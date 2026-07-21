# Databricks notebook source
# MAGIC %md
# MAGIC # JDBC Ingest — One Table
# MAGIC **for_each iteration** — reads one table from SQL Server → raw Delta.

# COMMAND ----------

dbutils.widgets.text("client_name",         "", "Client Name")
dbutils.widgets.text("src_schema_nm",       "", "Source Schema")
dbutils.widgets.text("src_tbl_nm",          "", "Source Table")
dbutils.widgets.text("primary_key",         "", "Primary Key")
dbutils.widgets.text("select_cols",         "", "Select Columns")
dbutils.widgets.text("partition_col",       "", "Partition Column")
dbutils.widgets.text("tbl_size",            "", "Table Size")
dbutils.widgets.text("effective_load_mode", "", "Effective Load Mode")
dbutils.widgets.text("ct_version_from",     "", "CT Version From")
dbutils.widgets.text("ct_version_to",       "", "CT Version To")

P = {k: dbutils.widgets.get(k) for k in [
    "client_name", "src_schema_nm", "src_tbl_nm", "primary_key",
    "select_cols", "partition_col", "tbl_size",
    "effective_load_mode", "ct_version_from", "ct_version_to",
]}

keys        = [k.strip() for k in P["primary_key"].split(",")]
_empty      = ("", "None", "null")
ct_from     = int(float(P["ct_version_from"])) if P["ct_version_from"] not in _empty else None
ct_to       = int(float(P["ct_version_to"]))   if P["ct_version_to"]   not in _empty else None
is_incr     = P["effective_load_mode"] == "incr" and ct_from is not None

catalog     = "ipac_tax_synch"
raw_schema  = "client_a_raw"
fq_source   = f"[{P['src_schema_nm']}].[{P['src_tbl_nm']}]"
fq_raw      = f"{catalog}.{raw_schema}.{P['src_tbl_nm']}"

print(f"Table: {fq_source} → {fq_raw}")
print(f"Mode:  {'INCR' if is_incr else 'FULL'}  CT: {ct_from} → {ct_to}")

# COMMAND ----------

import sys, json
from pyspark.sql.functions import lit

nb_path   = dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get()
repo_root = "/Workspace" + nb_path.rsplit("/src/", 1)[0]
if repo_root not in sys.path:
    sys.path.insert(0, repo_root)

import importlib
from src.utils.sqlserver.connection import jdbc_read, jdbc_read_table

client_module = importlib.import_module(f"config.clients.{P['client_name']}.connection")
source = client_module.CONNECTION["source"]

# COMMAND ----------

# MAGIC %md
# MAGIC ## JDBC Read → Raw Delta

# COMMAND ----------

select_cols = P["select_cols"]

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
        f"FROM CHANGETABLE(CHANGES {fq_source}, {ct_from}) AS ct "
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

    pc = P["partition_col"] if P["partition_col"] not in _empty else None
    np = 4 if P["tbl_size"] in ("medium", "large") and pc else None
    df = jdbc_read_table(spark, source, query, partition_col=pc, num_partitions=np)
    df = df.withColumn("_ct_op", lit("I")).withColumn("_ct_version", lit(ct_to))

write_mode = "append" if is_incr else "overwrite"
df.write.mode(write_mode).option("mergeSchema", "true").saveAsTable(fq_raw)

rows = df.count()
mode = "INCR" if is_incr else "FULL"
print(f"✓ {fq_source} → {fq_raw} ({mode}, {rows} rows)")

# COMMAND ----------

dbutils.notebook.exit(json.dumps({
    "table": P["src_tbl_nm"], "mode": mode, "rows": rows
}))