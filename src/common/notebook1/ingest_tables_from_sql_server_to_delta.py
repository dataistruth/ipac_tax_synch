# Databricks notebook source
# MAGIC %md
# MAGIC # 02 - Ingest Table (CT-based) + SCD1 Merge
# MAGIC Runs once **per table** inside the job's `for_each` task.
# MAGIC
# MAGIC Flow:
# MAGIC 1. Parse the table config passed by the for_each input
# MAGIC 2. Decide load mode:
# MAGIC    - `load_type = 'full'`            -> full extract every run
# MAGIC    - `last_ct_version IS NULL`       -> first run: full extract + capture current CT version
# MAGIC    - otherwise                       -> incremental via `CHANGETABLE(CHANGES ...)`
# MAGIC 3. Write to `client_a_silver_custom` using the common `scd1_merge` / `full_load`
# MAGIC 4. Update CT watermark + process log in Lakebase

# COMMAND ----------
import json
import sys
import traceback
from datetime import datetime, timezone

sys.path.append("../..")   # so `src.utils` resolves when run from notebook1/

from src.utils.common_functions import (
    scd1_merge,
    full_load,
    execute_lakebase_dml,
)

# COMMAND ----------
# -- Parameters ---------------------------------------------------------------
dbutils.widgets.text("table_config", "{}")   # injected by for_each: {{input}}
cfg = json.loads(dbutils.widgets.get("table_config"))

table_id       = cfg["table_id"]
client_id      = cfg["client_id"]
src_schema     = cfg["source_schema"]
src_table      = cfg["source_table"]
primary_keys   = [c.strip() for c in cfg["primary_keys"].split(",")]
sequence_key   = cfg.get("sequence_key") or None
cluster_by     = [c.strip() for c in cfg["cluster_by"].split(",")] if cfg.get("cluster_by") else None
load_type      = cfg["load_type"]                       # 'full' | 'incremental'
last_ct_version = cfg.get("last_ct_version")            # None => first load

TARGET_SCHEMA = f"{client_id}_silver_custom"            # e.g. client_a_silver_custom
TARGET_TABLE  = f"main.{TARGET_SCHEMA}.{src_table}"     # adjust catalog as needed

# -- Connections (secrets) ----------------------------------------------------
SQL_URL  = dbutils.secrets.get("sqlserver", "jdbc_url")  # jdbc:sqlserver://host;databaseName=db
SQL_USER = dbutils.secrets.get("sqlserver", "user")
SQL_PWD  = dbutils.secrets.get("sqlserver", "password")

LB_URL  = dbutils.secrets.get("lakebase", "jdbc_url")
LB_USER = dbutils.secrets.get("lakebase", "user")
LB_PWD  = dbutils.secrets.get("lakebase", "password")

run_id = dbutils.notebook.entry_point.getDbutils().notebook().getContext() \
    .currentRunId().toString() if True else "manual"

# COMMAND ----------
# -- Helpers ------------------------------------------------------------------
def sql_server_query(query: str):
    """Run a query against SQL Server via JDBC and return a DataFrame."""
    return (
        spark.read.format("jdbc")
        .option("url", SQL_URL)
        .option("driver", "com.microsoft.sqlserver.jdbc.SQLServerDriver")
        .option("query", query)
        .option("user", SQL_USER)
        .option("password", SQL_PWD)
        .load()
    )


def log_progress(status: str, message: str = None, rows: int = None,
                 ct_version: int = None):
    """Insert a row into the Lakebase process log."""
    execute_lakebase_dml(
        LB_URL, LB_USER, LB_PWD,
        """
        INSERT INTO config.process_log
            (run_id, client_id, table_id, source_table, status,
             message, row_count, ct_version, logged_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """,
        (run_id, client_id, table_id, src_table, status,
         message, rows, ct_version, datetime.now(timezone.utc)),
    )


def update_watermark(new_version: int):
    """Persist the CT version we've loaded up to."""
    execute_lakebase_dml(
        LB_URL, LB_USER, LB_PWD,
        """
        UPDATE config.table_config
        SET    last_ct_version = %s, last_loaded_at = %s
        WHERE  table_id = %s
        """,
        (new_version, datetime.now(timezone.utc), table_id),
    )

# COMMAND ----------
# -- Main ---------------------------------------------------------------------
log_progress("STARTED")

try:
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS main.{TARGET_SCHEMA}")

    # 1) Capture the current CT version BEFORE extracting, so changes that land
    #    mid-extract are picked up next run instead of being skipped.
    current_version = sql_server_query(
        "SELECT CHANGE_TRACKING_CURRENT_VERSION() AS v"
    ).collect()[0]["v"]

    is_full = (load_type == "full") or (last_ct_version is None)

    if is_full:
        # ---- FULL extract ---------------------------------------------------
        df = sql_server_query(f"SELECT * FROM [{src_schema}].[{src_table}]")
        row_count = df.count()

        if load_type == "full":
            result = full_load(spark, df, TARGET_TABLE, cluster_by=cluster_by)
        else:
            # first-time load of an incremental table -> seed via scd1
            result = scd1_merge(
                spark, df, TARGET_TABLE,
                primary_keys=primary_keys,
                sequence_key=sequence_key,
                cluster_by=cluster_by,
            )

    else:
        # ---- INCREMENTAL via Change Tracking --------------------------------
        # Validate the stored version is still within retention; if the min
        # valid version has moved past it, CT can no longer produce a complete
        # delta and we must fall back to a full re-seed.
        min_valid = sql_server_query(
            f"SELECT CHANGE_TRACKING_MIN_VALID_VERSION("
            f"OBJECT_ID('{src_schema}.{src_table}')) AS v"
        ).collect()[0]["v"]

        if min_valid is not None and last_ct_version < min_valid:
            log_progress("WARN", f"CT version {last_ct_version} < min valid "
                                 f"{min_valid}; falling back to full re-seed")
            df = sql_server_query(f"SELECT * FROM [{src_schema}].[{src_table}]")
            row_count = df.count()
            result = scd1_merge(spark, df, TARGET_TABLE,
                                primary_keys=primary_keys,
                                sequence_key=sequence_key,
                                cluster_by=cluster_by)
        else:
            join_on = " AND ".join(f"t.[{k}] = ct.[{k}]" for k in primary_keys)
            ct_keys = ", ".join(f"ct.[{k}] AS [__ct_{k}]" for k in primary_keys)
            ct_query = f"""
                SELECT t.*,
                       {ct_keys},
                       ct.SYS_CHANGE_OPERATION AS __op,
                       ct.SYS_CHANGE_VERSION   AS __ct_version
                FROM   CHANGETABLE(CHANGES [{src_schema}].[{src_table}],
                                   {last_ct_version}) AS ct
                LEFT JOIN [{src_schema}].[{src_table}] AS t
                       ON {join_on}
            """
            changes = sql_server_query(ct_query)
            row_count = changes.count()

            if row_count == 0:
                result = {"operation": "no_changes"}
            else:
                # Deletes: rows where SYS_CHANGE_OPERATION = 'D'
                # (source row is gone, so keys come from the __ct_* columns)
                ct_key_cols = [f"__ct_{k}" for k in primary_keys]
                deletes = (changes.filter("__op = 'D'")
                                  .select(*[F_col for F_col in ct_key_cols]))
                deletes = deletes.toDF(*primary_keys)  # rename __ct_x -> x

                upserts = (changes.filter("__op != 'D'")
                                  .drop("__op", "__ct_version", *ct_key_cols))

                if upserts.limit(1).count() > 0:
                    result = scd1_merge(
                        spark, upserts, TARGET_TABLE,
                        primary_keys=primary_keys,
                        sequence_key=sequence_key,
                        cluster_by=cluster_by,
                    )
                else:
                    result = {"operation": "deletes_only"}

                # SCD1 delete propagation (optional but usually wanted with CT)
                if deletes.limit(1).count() > 0:
                    deletes.createOrReplaceTempView("__del_keys")
                    on = " AND ".join(f"t.`{k}` = d.`{k}`" for k in primary_keys)
                    spark.sql(f"""
                        MERGE INTO {TARGET_TABLE} t
                        USING __del_keys d
                        ON {on}
                        WHEN MATCHED THEN DELETE
                    """)

    # 2) Advance the watermark only after a successful write
    update_watermark(current_version)
    log_progress("SUCCESS",
                 message=str(result.get("operation")),
                 rows=row_count if 'row_count' in dir() else None,
                 ct_version=current_version)

except Exception as e:
    log_progress("FAILED", message=f"{type(e).__name__}: {e}\n"
                                   f"{traceback.format_exc()[:2000]}")
    raise