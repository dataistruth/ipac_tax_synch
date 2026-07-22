# Databricks notebook source
# MAGIC %md
# MAGIC # Get Ingress Table List
# MAGIC **Task 1** — Check CT versions (pymssql, lightweight), build ingress list.

# COMMAND ----------

dbutils.widgets.text("client_name", "", "Client Name")
client_name = dbutils.widgets.get("client_name")
if not client_name:
    dbutils.notebook.exit("ERROR: client_name parameter is required")
print(f"Client: {client_name}")

# COMMAND ----------

import sys
nb_path   = dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get()
repo_root = "/Workspace" + nb_path.rsplit("/src/", 1)[0]
if repo_root not in sys.path:
    sys.path.insert(0, repo_root)
print(f"repo_root: {repo_root}")


# COMMAND ----------

# MAGIC %md
# MAGIC ## 1 — Pull active table config from Lakebase

# COMMAND ----------

from src.utils.lakebase.connection import fetch_all

active_tables = fetch_all(client_schema=client_name, sql="""
    SELECT src_schema_nm, src_tbl_nm, primary_key,
           target_schema, target_tbl_nm, tbl_size,
           load_mode, scd_type, cluster_keys, select_cols,
           sequence_key, last_ct_version,
           track_deletes, load_priority
      FROM table_config
     WHERE is_active = 'Y'
     ORDER BY load_priority, src_tbl_nm
""")

print(f"Active tables: {len(active_tables)}")
for t in active_tables:
    print(f"  {t['src_schema_nm']}.{t['src_tbl_nm']}  "
          f"mode={t['load_mode']}  last_ct={t['last_ct_version']}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2 — Load client connection config

# COMMAND ----------

import importlib
from src.utils.sqlserver.connection import fetch_one   # pymssql, not JDBC

client_module = importlib.import_module(f"config.clients.{client_name}.connection")
CONNECTION    = client_module.CONNECTION
source        = CONNECTION["source"]
print(f"Source: {source['host']} / {source['database']}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3 — Get current CT version (pymssql — milliseconds, no Spark)

# COMMAND ----------

row = fetch_one(source, "SELECT CHANGE_TRACKING_CURRENT_VERSION() AS current_version")
db_current_version = row["current_version"]
print(f"SQL Server CHANGE_TRACKING_CURRENT_VERSION = {db_current_version}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4 — Per-table: check min valid version and decide load action

# COMMAND ----------

unload_list = []
skipped     = []

for tbl_cfg in active_tables:
    schema   = tbl_cfg["src_schema_nm"]
    table    = tbl_cfg["src_tbl_nm"]
    last_ver = tbl_cfg["last_ct_version"]
    fq_table = f"[{schema}].[{table}]"

    if tbl_cfg["load_mode"] == "full":
        entry = {**tbl_cfg, "effective_load_mode": "full",
                 "ct_version_from": None, "ct_version_to": int(db_current_version)}
        unload_list.append(entry)
        print(f"  ✓ {fq_table} → FULL (configured)")
        continue

    # pymssql — lightweight per-table CT check
    mv = fetch_one(source,
        f"SELECT CHANGE_TRACKING_MIN_VALID_VERSION("
        f"OBJECT_ID('{schema}.{table}')) AS min_valid_version")
    min_valid = mv["min_valid_version"]

    if last_ver >= db_current_version:
        skipped.append(f"{fq_table} (ct={last_ver}, current={db_current_version})")
        print(f"  – {fq_table} → SKIP (no changes)")
        continue

    if last_ver == 0 or min_valid is None or min_valid > last_ver:
        reason = "first load" if last_ver == 0 else "CT retention expired"
        entry = {**tbl_cfg, "effective_load_mode": "full",
                 "ct_version_from": None, "ct_version_to": int(db_current_version)}
        unload_list.append(entry)
        print(f"  ✓ {fq_table} → FULL ({reason}, min_valid={min_valid})")
        continue

    entry = {**tbl_cfg, "effective_load_mode": "incr",
             "ct_version_from": int(last_ver), "ct_version_to": int(db_current_version)}
    unload_list.append(entry)
    print(f"  ✓ {fq_table} → INCR (from={last_ver} to={db_current_version})")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 5 — Summary

# COMMAND ----------

print("=" * 60)
print(f"Tables to load : {len(unload_list)}")
print(f"Tables skipped : {len(skipped)}")
for s in skipped:
    print(f"    {s}")
print("=" * 60)

if not unload_list:
    print("Nothing to load — pipeline will process zero new data.")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 6 — Publish task value

# COMMAND ----------

import json, decimal

def _clean(obj):
    if isinstance(obj, decimal.Decimal):
        return int(obj) if obj == int(obj) else float(obj)
    return obj

serializable_list = [
    {k: _clean(v) for k, v in entry.items()}
    for entry in unload_list
]

dbutils.jobs.taskValues.set(key="unload_list", value=json.dumps(serializable_list))

print(f"Task value 'unload_list' set — {len(serializable_list)} entries")
if serializable_list:
    print("\nSample entry:")
    print(json.dumps(serializable_list[0], indent=2))