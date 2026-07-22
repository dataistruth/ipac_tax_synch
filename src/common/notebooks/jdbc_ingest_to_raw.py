# Databricks notebook source
# MAGIC %md
# MAGIC # JDBC Ingest to Raw
# MAGIC **Task 2** — Reads from SQL Server, writes to raw Delta tables.
# MAGIC Runs BEFORE the SDP pipeline (Task 3).

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

import importlib
from pyspark.sql.functions import lit
from src.utils.lakebase.connection import fetch_all
from src.utils.sqlserver.connection import fetch_one, jdbc_read

client_module = importlib.import_module(f"config.clients.{client_name}.connection")
CONNECTION    = client_module.CONNECTION
source        = CONNECTION["source"]

catalog    = "ipac_tax_synch"
raw_schema = "client_a_raw"

print(f"Source: {source['host']} / {source['database']}")
print(f"Target: {catalog}.{raw_schema}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Load table config + CT version

# COMMAND ----------

table_configs = fetch_all(client_schema=client_name, sql="""
    SELECT src_schema_nm, src_tbl_nm, target_tbl_nm,
           primary_key, select_cols, tbl_size,
           load_mode, last_ct_version
      FROM table_config
     WHERE is_active = 'Y'
     ORDER BY load_priority, src_tbl_nm
""")

row = fetch_one(source, "SELECT CHANGE_TRACKING_CURRENT_VERSION() AS ver")
db_ct_version = int(row["ver"])

print(f"Active tables: {len(table_configs)}")
print(f"CT current version: {db_ct_version}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## JDBC read → raw Delta tables

# COMMAND ----------

spark.sql(f"CREATE SCHEMA IF NOT EXISTS {catalog}.{raw_schema}")

for tbl in table_configs:
    schema_nm   = tbl["src_schema_nm"]
    src_table   = tbl["src_tbl_nm"]
    fq_source   = f"[{schema_nm}].[{src_table}]"
    fq_raw      = f"{catalog}.{raw_schema}.{src_table}"
    last_ct     = int(tbl["last_ct_version"])
    keys        = [k.strip() for k in tbl["primary_key"].split(",")]
    select_cols = tbl.get("select_cols", "*")
    tbl_size    = tbl.get("tbl_size", "small")

    is_incr = (tbl["load_mode"] == "incr"
               and last_ct > 0
               and last_ct < db_ct_version)

    if is_incr:
        if select_cols and select_cols.strip() != "*":
            data_cols = [f"t.[{c.strip()}]" for c in select_cols.split(",")]
        else:
            data_cols = ["t.*"]
        key_select  = ", ".join(f"ct.[{c}]" for c in keys)
        data_select = ", ".join(data_cols)
        query = (
            f"SELECT ct.SYS_CHANGE_OPERATION AS _ct_op, "
            f"ct.SYS_CHANGE_VERSION AS _ct_version, "
            f"{key_select}, {data_select} "
            f"FROM CHANGETABLE(CHANGES {fq_source}, {last_ct}) AS ct "
            f"LEFT JOIN {fq_source} AS t ON "
            + " AND ".join(f"ct.[{c}] = t.[{c}]" for c in keys)
        )
        df = jdbc_read(spark, source, query)
    else:
        if select_cols and select_cols.strip() != "*":
            col_list = ", ".join(f"[{c.strip()}]" for c in select_cols.split(","))
            query = f"SELECT {col_list} FROM {fq_source}"
        else:
            query = f"SELECT * FROM {fq_source}"

        df = jdbc_read(spark, source, query)
        df = (df.withColumn("_ct_op", lit("I"))
                .withColumn("_ct_version", lit(db_ct_version)))

    write_mode = "append" if is_incr else "overwrite"
    df.write.mode(write_mode).option("mergeSchema", "true").saveAsTable(fq_raw)

    mode = "INCR" if is_incr else "FULL"
    print(f"  ✓ {fq_source} → {fq_raw} ({mode})")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Store CT version for post-pipeline update

# COMMAND ----------

import json
dbutils.jobs.taskValues.set(key="db_ct_version", value=db_ct_version)
print(f"CT version {db_ct_version} passed to downstream tasks")