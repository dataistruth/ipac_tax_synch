# Databricks notebook source
# MAGIC %md
# MAGIC # Update Lakebase
# MAGIC **Task 4** — Updates `last_ct_version` + `process_log` after pipeline succeeds.

# COMMAND ----------

dbutils.widgets.text("client_name", "", "Client Name")
client_name = dbutils.widgets.get("client_name")
print(f"Client: {client_name}")

# COMMAND ----------

import sys
nb_path   = dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get()
repo_root = "/Workspace" + nb_path.rsplit("/src/", 1)[0]
if repo_root not in sys.path:
    sys.path.insert(0, repo_root)

# COMMAND ----------

from src.utils.lakebase.connection import fetch_all, execute

# Get CT version from Task 2 (falls back to reading from SQL Server if interactive)
try:
    db_ct_version = int(dbutils.jobs.taskValues.get(
        taskKey="jdbc_ingest_to_raw", key="db_ct_version"))
except Exception:
    # Interactive run — read CT version from SQL Server directly
    import importlib
    from src.utils.sqlserver.connection import fetch_one
    client_module = importlib.import_module(f"config.clients.{client_name}.connection")
    source = client_module.CONNECTION["source"]
    row = fetch_one(source, "SELECT CHANGE_TRACKING_CURRENT_VERSION() AS ver")
    db_ct_version = int(row["ver"])

print(f"CT version to commit: {db_ct_version}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Update last_ct_version for all active tables

# COMMAND ----------

table_configs = fetch_all(client_schema=client_name, sql="""
    SELECT src_schema_nm, src_tbl_nm
      FROM table_config
     WHERE is_active = 'Y'
""")

# Get job run ID (safe for both job and interactive contexts)
try:
    ctx = dbutils.notebook.entry_point.getDbutils().notebook().getContext()
    job_run_id = ctx.jobRunId().getOrElse(None) or "interactive"
except Exception:
    job_run_id = "interactive"

print(f"Job run ID: {job_run_id}")

for tbl in table_configs:
    execute(client_schema=client_name, sql="""
        UPDATE table_config
           SET last_ct_version = %s,
               last_status     = 'SUCCESS',
               update_dttm     = now()
         WHERE src_schema_nm = %s AND src_tbl_nm = %s
    """, params=(db_ct_version, tbl["src_schema_nm"], tbl["src_tbl_nm"]))

    execute(client_schema=client_name, sql="""
        INSERT INTO process_log
            (job_id, task_id, task_type, object_nm, load_mode,
             ct_version_to, start_time, end_time, status)
        VALUES
            (%s, 'refresh_silver', 'ingress', %s, 'pipeline',
             %s, now(), now(), 'SUCCESS')
    """, params=(job_run_id, tbl["src_tbl_nm"], db_ct_version))

print(f"Lakebase updated: {len(table_configs)} tables → CT version {db_ct_version}")