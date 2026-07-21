"""
common_functions.py
===================
Reusable write utilities for the SQL Server -> Delta ingestion framework.

Exposes:
    - scd1_merge()   : SCD Type 1 upsert (dedupe on PK, MERGE into Delta target)
    - full_load()    : Full overwrite write for tables flagged as "full"
    - apply_liquid_clustering() : Apply / update CLUSTER BY on an existing table

Usage (from notebook2):
    from src.utils.common_functions import scd1_merge, full_load

    if load_type == "full":
        full_load(spark, df, target_table, cluster_by=cluster_cols)
    else:
        scd1_merge(
            spark,
            source_df=df,
            target_table=target_table,
            primary_keys=pk_cols,          # e.g. ["entity_id"]
            sequence_key=seq_col,          # e.g. "modified_ts" (optional)
            cluster_by=cluster_cols,       # e.g. ["entity_id"] (optional)
        )
"""

import logging
from typing import List, Optional

from pyspark.sql import DataFrame, SparkSession, Window
from pyspark.sql import functions as F
from delta.tables import DeltaTable

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")


# --------------------------------------------------------------------------- #
# Internal helpers
# --------------------------------------------------------------------------- #
def _validate_inputs(source_df: DataFrame, primary_keys: List[str],
                     sequence_key: Optional[str]) -> Optional[str]:
    """
    Fail fast on bad primary keys; sequence_key is soft-optional.

    Returns the effective sequence_key: the one passed in if it exists in the
    DataFrame, otherwise None (with a warning) so dedupe falls back to
    picking a single arbitrary record per key.
    """
    if not primary_keys:
        raise ValueError("primary_keys must be a non-empty list for SCD1 merge.")

    missing = [c for c in primary_keys if c not in source_df.columns]
    if missing:
        raise ValueError(f"Primary key column(s) {missing} not found in source DataFrame. "
                         f"Available columns: {source_df.columns}")

    if sequence_key and sequence_key not in source_df.columns:
        logger.warning(
            "sequence_key '%s' not found in source columns - ignoring it; "
            "dedupe will keep one arbitrary record per primary key.",
            sequence_key,
        )
        return None

    return sequence_key


def _dedupe_source(source_df: DataFrame, primary_keys: List[str],
                   sequence_key: Optional[str]) -> DataFrame:
    """
    Keep exactly one row per primary key.

    - If a sequence_key is defined, keep the row with the highest sequence value
      (latest change wins).
    - If not, keep an arbitrary single row (dedupe is still mandatory because
      Delta MERGE fails if multiple source rows match one target row).
    """
    if sequence_key:
        order_col = F.col(sequence_key).desc_nulls_last()
    else:
        order_col = F.monotonically_increasing_id().desc()

    w = Window.partitionBy(*primary_keys).orderBy(order_col)
    return (
        source_df
        .withColumn("__rn", F.row_number().over(w))
        .filter(F.col("__rn") == 1)
        .drop("__rn")
    )


def _table_exists(spark: SparkSession, target_table: str) -> bool:
    return spark.catalog.tableExists(target_table)


def _create_table(source_df: DataFrame, target_table: str,
                  cluster_by: Optional[List[str]]) -> None:
    """First load: create the target table (with liquid clustering, no partitioning)."""
    writer = source_df.write.format("delta")
    if cluster_by:
        writer = writer.clusterBy(*cluster_by)
    writer.saveAsTable(target_table)
    logger.info("Created target table %s (cluster_by=%s)", target_table, cluster_by)


# --------------------------------------------------------------------------- #
# Public API
# --------------------------------------------------------------------------- #
def scd1_merge(
    spark: SparkSession,
    source_df: DataFrame,
    target_table: str,
    primary_keys: List[str],
    sequence_key: Optional[str] = None,
    cluster_by: Optional[List[str]] = None,
    merge_schema: bool = True,
) -> dict:
    """
    SCD Type 1 upsert into a Delta table.

    Behaviour:
        1. Dedupe the incoming batch on primary_keys (latest by sequence_key wins).
        2. If the target does not exist -> create it (CLUSTER BY, no PARTITION BY).
        3. Otherwise MERGE:
             - matched  -> UPDATE SET *   (only if incoming row is newer, when
                                           sequence_key is defined)
             - not matched -> INSERT *

    Args:
        spark:         Active SparkSession.
        source_df:     Incremental batch pulled from SQL Server.
        target_table:  Fully-qualified UC name, e.g. "catalog.schema.table".
        primary_keys:  Business/primary key column(s) to match on.
        sequence_key:  Optional ordering column (e.g. modified_ts, LSN, version).
                       Prevents an old late-arriving row from overwriting newer data.
        cluster_by:    Optional liquid-clustering columns (used on table creation).
        merge_schema:  Allow automatic schema evolution during merge (default True).

    Returns:
        dict with basic merge metrics (rows in batch after dedupe, operation).
    """
    sequence_key = _validate_inputs(source_df, primary_keys, sequence_key)

    deduped = _dedupe_source(source_df, primary_keys, sequence_key)

    # ---- First load: just create the table -------------------------------- #
    if not _table_exists(spark, target_table):
        _create_table(deduped, target_table, cluster_by)
        return {"operation": "create", "target": target_table}

    # ---- Incremental: Delta MERGE ----------------------------------------- #
    if merge_schema:
        spark.conf.set("spark.databricks.delta.schema.autoMerge.enabled", "true")

    merge_condition = " AND ".join(f"t.`{k}` = s.`{k}`" for k in primary_keys)

    # Only overwrite the target row if the incoming row is at least as new.
    update_condition = None
    if sequence_key:
        update_condition = f"s.`{sequence_key}` >= t.`{sequence_key}`"

    target = DeltaTable.forName(spark, target_table)
    merge_builder = (
        target.alias("t")
        .merge(deduped.alias("s"), merge_condition)
    )

    if update_condition:
        merge_builder = merge_builder.whenMatchedUpdateAll(condition=update_condition)
    else:
        merge_builder = merge_builder.whenMatchedUpdateAll()

    merge_builder = merge_builder.whenNotMatchedInsertAll()
    merge_builder.execute()

    logger.info("SCD1 merge into %s complete (keys=%s, sequence_key=%s)",
                target_table, primary_keys, sequence_key)

    return {"operation": "merge", "target": target_table,
            "primary_keys": primary_keys, "sequence_key": sequence_key}


def full_load(
    spark: SparkSession,
    source_df: DataFrame,
    target_table: str,
    cluster_by: Optional[List[str]] = None,
) -> dict:
    """
    Full overwrite for tables configured as load_type = 'full'.

    Uses INSERT OVERWRITE semantics on an existing table (keeps table identity,
    history, and clustering spec) or creates the table on first run.
    NOTE: any streaming reader on this table must use skipChangeCommits or be
    a materialized view, since this is a data rewrite.
    """
    if not _table_exists(spark, target_table):
        _create_table(source_df, target_table, cluster_by)
        return {"operation": "create", "target": target_table}

    # Overwrite with clusterBy declared in the writer itself: the clustering
    # spec is applied as part of this single write (no extra ALTER TABLE hop),
    # and with overwriteSchema=true it survives schema changes too.
    writer = (
        source_df.write.format("delta")
        .mode("overwrite")
        .option("overwriteSchema", "true")
    )
    if cluster_by:
        writer = writer.clusterBy(*cluster_by)
    writer.saveAsTable(target_table)
    logger.info("Full overwrite of %s complete", target_table)
    return {"operation": "overwrite", "target": target_table}


def read_lakebase_df(
    spark: SparkSession,
    query: str,
    jdbc_url: str,
    user: str,
    password: str,
) -> DataFrame:
    """
    Read the result of a SQL query from Lakebase (Postgres) as a DataFrame.

    Example:
        df = read_lakebase_df(spark,
            "SELECT * FROM config.table_config WHERE client_id='client_a' AND is_active",
            jdbc_url, user, password)
    """
    return (
        spark.read.format("jdbc")
        .option("url", jdbc_url)
        .option("driver", "org.postgresql.Driver")
        .option("query", query)
        .option("user", user)
        .option("password", password)
        .load()
    )


def execute_lakebase_dml(
    jdbc_url: str,
    user: str,
    password: str,
    sql: str,
    params: Optional[tuple] = None,
) -> None:
    """
    Execute an INSERT/UPDATE against Lakebase (Postgres) via psycopg2.
    Used for process-log writes and CT watermark updates (single-row DML,
    so JDBC dataframe writes would be overkill).
    """
    import psycopg2
    from urllib.parse import urlparse

    parsed = urlparse(jdbc_url.replace("jdbc:", ""))
    conn = psycopg2.connect(
        host=parsed.hostname,
        port=parsed.port or 5432,
        dbname=parsed.path.lstrip("/").split("?")[0],
        user=user,
        password=password,
        sslmode="require",
    )
    try:
        with conn, conn.cursor() as cur:
            cur.execute(sql, params or ())
    finally:
        conn.close()


def apply_liquid_clustering(
    spark: SparkSession,
    target_table: str,
    cluster_by: List[str],
    run_optimize: bool = False,
) -> bool:
    """
    MAINTENANCE-ONLY helper. Do NOT call this in the per-run ingest path —
    clustering is already declared at write time (clusterBy in _create_table
    and full_load), so no ALTER TABLE hop is needed during normal loads.

    Use this only when the cluster_by columns in config have CHANGED for an
    existing table. It first compares against the table's current clustering
    (cheap metadata read) and no-ops if they already match.

    Returns True if an ALTER was actually applied, False if skipped.
    """
    current = (
        spark.sql(f"DESCRIBE DETAIL {target_table}")
        .select("clusteringColumns").collect()[0][0] or []
    )
    if list(current) == list(cluster_by):
        logger.info("Clustering on %s already %s - skipping ALTER", target_table, cluster_by)
        return False

    cols = ", ".join(f"`{c}`" for c in cluster_by)
    spark.sql(f"ALTER TABLE {target_table} CLUSTER BY ({cols})")
    logger.info("Changed CLUSTER BY on %s: %s -> %s", target_table, current, cluster_by)

    # OPTIMIZE physically re-clusters existing files. Expensive; run it from a
    # scheduled maintenance job, not the ingest hot path.
    if run_optimize:
        spark.sql(f"OPTIMIZE {target_table}")
    return True