# Databricks notebook source
# MAGIC %md
# MAGIC # 01 - Get Active Tables
# MAGIC Reads `table_config` from **Lakebase** for the client schema and returns
# MAGIC the active table list as a task value for the job `for_each` task.
# MAGIC
# MAGIC Credentials: `config/base_config.py` + Databricks secret scope
# MAGIC (`client-a-secrets` via `src.utils.lakebase.connection`).

# COMMAND ----------

import json
import sys

dbutils.widgets.text("client_id", "client_a")
dbutils.widgets.text("dest_catalog", "")

client_id = dbutils.widgets.get("client_id")
dest_catalog = dbutils.widgets.get("dest_catalog").strip()
print(f"client_id: {client_id}")
print(f"dest_catalog: {dest_catalog or '(from base_config fallback)'}")

# COMMAND ----------

nb_path   = dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get()
repo_root = "/Workspace" + nb_path.rsplit("/src/", 1)[0]
if repo_root not in sys.path:
    sys.path.insert(0, repo_root)
print(f"repo_root: {repo_root}")

# COMMAND ----------

from config.base_config import BASE_CONFIG
from src.utils.lakebase.connection import fetch_all

import importlib
client_module = importlib.import_module(f"config.clients.{client_id}.connection")
default_source_schema = client_module.CONNECTION["source"].get("schema", "dbo")

if not dest_catalog:
    dest_catalog = BASE_CONFIG.get("dest_catalog", "")

rows = fetch_all(
    client_schema=client_id,
    dbutils=dbutils,
    sql="""
        SELECT src_schema_nm,
               src_tbl_nm,
               primary_key,
               cluster_keys,
               sequence_key,
               load_mode,
               last_ct_version
          FROM table_config
         WHERE is_active = 'Y'
         ORDER BY load_priority, src_tbl_nm
    """,
)

# Map Lakebase columns -> for_each payload expected by ingest notebook
tables = []
for row in rows:
    last_ct = row.get("last_ct_version")
    tables.append({
        "table_id":        f"{row['src_schema_nm']}.{row['src_tbl_nm']}",
        "client_id":       client_id,
        "source_schema":   row["src_schema_nm"] or default_source_schema,
        "source_table":    row["src_tbl_nm"],
        "primary_keys":    row["primary_key"],
        "sequence_key":    row.get("sequence_key"),
        "cluster_by":      row.get("cluster_keys"),
        "load_type":       "full" if row["load_mode"] == "full" else "incr",
        "last_ct_version": None if last_ct in (None, 0) else int(last_ct),
    })

print(f"Found {len(tables)} active table(s) for {client_id}")
for t in tables:
    print(
        f"  - {t['source_schema']}.{t['source_table']} "
        f"(load_type={t['load_type']}, last_ct_version={t['last_ct_version']})"
    )

# COMMAND ----------

dbutils.jobs.taskValues.set(key="active_tables", value=json.dumps(tables))
