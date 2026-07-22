# Databricks notebook source
# MAGIC %md
# MAGIC # 02 - Ingest Table (SQL Server → Delta)
# MAGIC - **full** load: Delta overwrite (`full_load`)
# MAGIC - **incr** load: CT-based SCD1 merge + deletes
# MAGIC Runs once **per table** inside the job's `for_each` task.
# MAGIC
# MAGIC Credentials:
# MAGIC - SQL Server: `config/clients/{client_id}/connection.py` + `client-a-secrets`
# MAGIC - Lakebase: `config/base_config.py` + `client-a-secrets`

# COMMAND ----------

import importlib
import json
import sys

dbutils.widgets.text("table_config", "{}")
dbutils.widgets.text("dest_catalog", "")

cfg = json.loads(dbutils.widgets.get("table_config"))
dest_catalog_param = dbutils.widgets.get("dest_catalog").strip()

table_id        = cfg["table_id"]
client_id       = cfg["client_id"]
src_schema      = cfg["source_schema"]
src_table       = cfg["source_table"]
primary_keys    = [c.strip() for c in cfg["primary_keys"].split(",")]
sequence_key    = cfg.get("sequence_key") or None
cluster_by      = (
    [c.strip() for c in cfg["cluster_by"].split(",")]
    if cfg.get("cluster_by") else None
)
load_type       = cfg["load_type"]
_raw_ct_version = cfg.get("last_ct_version")
if _raw_ct_version in (None, "", 0):
    last_ct_version = None
else:
    last_ct_version = int(_raw_ct_version)

# COMMAND ----------

nb_path   = dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get()
repo_root = "/Workspace" + nb_path.rsplit("/src/", 1)[0]
if repo_root not in sys.path:
    sys.path.insert(0, repo_root)

from config.base_config import BASE_CONFIG
from src.utils.common_functions import full_load, scd1_merge
from src.utils.lakebase.connection import execute
from src.utils.lakebase.process_log import write_process_log
from src.utils.sqlserver.connection import jdbc_read

client_module = importlib.import_module(f"config.clients.{client_id}.connection")
source = client_module.CONNECTION["source"]

# Source schema: per-table from Lakebase table_config; fallback to connection.py default
if not src_schema:
    src_schema = source.get("schema", "dbo")

CATALOG = dest_catalog_param or BASE_CONFIG.get("dest_catalog", "")
if not CATALOG:
    raise ValueError(
        "dest_catalog is required. Pass job parameter dest_catalog "
        "(bundle var: ${var.dest_catalog}) or set base_config.dest_catalog."
    )

TARGET_SCHEMA = f"{client_id}_silver_custom"
TARGET_TABLE  = f"{CATALOG}.{TARGET_SCHEMA}.{src_table}"

try:
    ctx = dbutils.notebook.entry_point.getDbutils().notebook().getContext()
    job_run_id = str(ctx.jobRunId().getOrElse("interactive"))
    task_run_id = str(ctx.currentRunId().getOrElse("manual"))
except Exception:
    job_run_id = "interactive"
    task_run_id = "manual"

print(f"Source: {source['host']} / {source['database']} / schema={src_schema}")
print(f"Catalog: {CATALOG}")
print(f"Target: {TARGET_TABLE}")
print(f"Table:  {src_schema}.{src_table}  load_type={load_type}  last_ct={last_ct_version}")

# COMMAND ----------

def sql_server_query(query: str):
    """Run a query against SQL Server via JDBC and return a DataFrame."""
    return jdbc_read(spark, source, query, dbutils=dbutils)


def log_progress(
    status: str,
    message: str | None = None,
    rows: int | None = None,
    ct_version: int | None = None,
    load_mode: str | None = None,
):
    """Insert a row into the client process_log table in Lakebase."""
    write_process_log(
        client_schema=client_id,
        job_id=job_run_id,
        task_id=task_run_id,
        object_nm=src_table,
        status=status,
        message=message,
        load_mode=load_mode or load_type,
        ct_version_to=ct_version,
        rows_written=rows,
        dbutils=dbutils,
    )


def update_watermark(new_version: int):
    """Persist the CT version loaded up to for this table."""
    execute(
        client_schema=client_id,
        dbutils=dbutils,
        sql="""
            UPDATE table_config
               SET last_ct_version = %s,
                   last_status     = 'SUCCESS',
                   update_dttm     = now()
             WHERE src_schema_nm = %s
               AND src_tbl_nm    = %s
        """,
        params=(new_version, src_schema, src_table),
    )

# COMMAND ----------

log_progress("RUNNING", load_mode=load_type)
result = {}

try:
    spark.sql(f"CREATE SCHEMA IF NOT EXISTS {CATALOG}.{TARGET_SCHEMA}")

    current_version = int(
        sql_server_query("SELECT CHANGE_TRACKING_CURRENT_VERSION() AS v")
        .collect()[0]["v"]
    )

    if load_type == "full":
        df = sql_server_query(f"SELECT * FROM [{src_schema}].[{src_table}]")
        result = full_load(spark, df, TARGET_TABLE, cluster_by=cluster_by)
    elif last_ct_version is None:
        df = sql_server_query(f"SELECT * FROM [{src_schema}].[{src_table}]")
        result = scd1_merge(
            spark, df, TARGET_TABLE,
            primary_keys=primary_keys,
            sequence_key=sequence_key,
            cluster_by=cluster_by,
        )
    else:
        min_valid_raw = sql_server_query(
            f"SELECT CHANGE_TRACKING_MIN_VALID_VERSION("
            f"OBJECT_ID('{src_schema}.{src_table}')) AS v"
        ).collect()[0]["v"]
        min_valid = int(min_valid_raw) if min_valid_raw is not None else None

        if min_valid is not None and last_ct_version < min_valid:
            log_progress(
                "SKIPPED",
                message=f"CT version {last_ct_version} < min valid {min_valid}; full re-seed",
                load_mode=load_type,
            )
            df = sql_server_query(f"SELECT * FROM [{src_schema}].[{src_table}]")
            result = scd1_merge(
                spark, df, TARGET_TABLE,
                primary_keys=primary_keys,
                sequence_key=sequence_key,
                cluster_by=cluster_by,
            )
        else:
            join_on = " AND ".join(f"t.[{k}] = ct.[{k}]" for k in primary_keys)

            op_types = {
                row["__op"]
                for row in sql_server_query(f"""
                    SELECT DISTINCT ct.SYS_CHANGE_OPERATION AS __op
                    FROM   CHANGETABLE(CHANGES [{src_schema}].[{src_table}],
                                       {last_ct_version}) AS ct
                """).collect()
            }

            if not op_types:
                result = {"operation": "no_changes"}
            else:
                if any(op != "D" for op in op_types):
                    upserts = sql_server_query(f"""
                        SELECT t.*
                        FROM   CHANGETABLE(CHANGES [{src_schema}].[{src_table}],
                                           {last_ct_version}) AS ct
                        INNER JOIN [{src_schema}].[{src_table}] AS t
                                ON {join_on}
                        WHERE  ct.SYS_CHANGE_OPERATION != 'D'
                    """)
                    result = scd1_merge(
                        spark, upserts, TARGET_TABLE,
                        primary_keys=primary_keys,
                        sequence_key=sequence_key,
                        cluster_by=cluster_by,
                    )
                else:
                    result = {"operation": "deletes_only"}

                if "D" in op_types:
                    delete_cols = ", ".join(f"ct.[{k}]" for k in primary_keys)
                    deletes = sql_server_query(f"""
                        SELECT {delete_cols}
                        FROM   CHANGETABLE(CHANGES [{src_schema}].[{src_table}],
                                           {last_ct_version}) AS ct
                        WHERE  ct.SYS_CHANGE_OPERATION = 'D'
                    """)
                    deletes.createOrReplaceTempView("__del_keys")
                    on = " AND ".join(f"t.`{k}` = d.`{k}`" for k in primary_keys)
                    spark.sql(f"""
                        MERGE INTO {TARGET_TABLE} t
                        USING __del_keys d
                        ON {on}
                        WHEN MATCHED THEN DELETE
                    """)

    update_watermark(current_version)
    log_progress(
        "SUCCESS",
        message=str(result.get("operation")),
        ct_version=current_version,
        load_mode=load_type,
    )

except Exception as exc:
    log_progress(
        "FAILED",
        message=f"{type(exc).__name__}: {exc}",
        load_mode=load_type,
    )
    raise
