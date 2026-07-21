# Databricks notebook source
# MAGIC %md
# MAGIC # 01 - Get Active Tables
# MAGIC Reads the control config in **Lakebase (Postgres)** and returns the list of
# MAGIC active tables for the given client as a task value, which the job's
# MAGIC `for_each` task fans out over.

# COMMAND ----------
import json
import sys

# Adjust to wherever the repo is mounted:
sys.path.append("../..")   # so `src.utils` resolves when run from notebook1/

from src.utils.common_functions import read_lakebase_df

# COMMAND ----------
# -- Widgets / parameters -----------------------------------------------------
dbutils.widgets.text("client_id", "client_a")
client_id = dbutils.widgets.get("client_id")

# -- Lakebase connection (secrets, never hardcode) ----------------------------
LB_URL  = dbutils.secrets.get("lakebase", "jdbc_url")     # jdbc:postgresql://host:5432/db
LB_USER = dbutils.secrets.get("lakebase", "user")
LB_PWD  = dbutils.secrets.get("lakebase", "password")

# COMMAND ----------
# -- Fetch active tables for this client --------------------------------------
query = f"""
    SELECT table_id,
           source_schema,
           source_table,
           primary_keys,          -- comma separated, e.g. 'entity_id'
           sequence_key,          -- nullable
           cluster_by,            -- comma separated, nullable
           load_type,             -- 'full' | 'incremental'
           last_ct_version        -- nullable: NULL => never loaded => full refresh
    FROM   config.table_config
    WHERE  client_id = '{client_id}'
      AND  is_active = true
"""
cfg_df = read_lakebase_df(spark, query, LB_URL, LB_USER, LB_PWD)

tables = [
    {
        "table_id":       r["table_id"],
        "client_id":      client_id,
        "source_schema":  r["source_schema"],
        "source_table":   r["source_table"],
        "primary_keys":   r["primary_keys"],
        "sequence_key":   r["sequence_key"],
        "cluster_by":     r["cluster_by"],
        "load_type":      r["load_type"],
        "last_ct_version": r["last_ct_version"],
    }
    for r in cfg_df.collect()
]

print(f"Found {len(tables)} active table(s) for {client_id}")
for t in tables:
    print(f"  - {t['source_schema']}.{t['source_table']} "
          f"(load_type={t['load_type']}, last_ct_version={t['last_ct_version']})")

# COMMAND ----------
# -- Hand off to the for_each task -------------------------------------------
dbutils.jobs.taskValues.set(key="active_tables", value=json.dumps(tables))