# Databricks notebook source
# MAGIC %md
# MAGIC # Silver Ingestion — SDP Pipeline
# MAGIC **Task 2** — JDBC Read → Staged View → Auto CDC → Silver
# MAGIC
# MAGIC Processes ALL active tables from Lakebase `table_config`.
# MAGIC SDP manages concurrency, parallelism, and dependency resolution.
# MAGIC
# MAGIC Per table:
# MAGIC 1. `@dp.temporary_view` — JDBC read from SQL Server (full or CT delta)
# MAGIC 2. `dp.create_streaming_table` — silver target
# MAGIC 3. `dp.create_auto_cdc_flow` — SCD Type 1 or 2

# COMMAND ----------

# MAGIC %md
# MAGIC ## Setup

# COMMAND ----------

import sys, os
from pyspark import pipelines as dp
from pyspark.sql.functions import col, lit

# ── Pipeline configuration (from YAML) ────────────────────────────────────
client_name   = spark.conf.get("client_name")
catalog       = spark.conf.get("catalog")
target_schema = spark.conf.get("target_schema")

# Repo root
nb_path   = dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get()
repo_root = "/Workspace" + nb_path.rsplit("/src/", 1)[0]
if repo_root not in sys.path:
    sys.path.insert(0, repo_root)

import importlib
from src.utils.lakebase.connection import fetch_all, execute
from src.utils.sqlserver.connection import jdbc_read

client_module = importlib.import_module(f"config.clients.{client_name}.connection")
CONNECTION    = client_module.CONNECTION
source        = CONNECTION["source"]

print(f"Client:  {client_name}")
print(f"Source:  {source['host']} / {source['database']}")
print(f"Target:  {catalog}.{target_schema}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Load table config from Lakebase

# COMMAND ----------

table_configs = fetch_all(client_schema=client_name, sql="""
    SELECT src_schema_nm, src_tbl_nm, target_tbl_nm,
           primary_key, scd_type, sequence_key, select_cols,
           cluster_keys, track_deletes, tbl_size,
           load_mode, last_ct_version
      FROM table_config
     WHERE is_active = 'Y'
     ORDER BY load_priority, src_tbl_nm
""")

print(f"Active tables: {len(table_configs)}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Get current CT version (database-level, one call)

# COMMAND ----------

ct_current_df = jdbc_read(
    spark, source,
    "SELECT CHANGE_TRACKING_CURRENT_VERSION() AS current_version"
)
db_ct_version = int(ct_current_df.first()["current_version"])
print(f"SQL Server CT current version: {db_ct_version}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Generate SDP objects per table

# COMMAND ----------

for tbl in table_configs:
    schema_nm    = tbl["src_schema_nm"]
    src_table    = tbl["src_tbl_nm"]
    target_table = tbl["target_tbl_nm"]
    keys         = [k.strip() for k in tbl["primary_key"].split(",")]
    scd_type     = str(tbl["scd_type"])
    seq_key      = tbl.get("sequence_key")
    select_cols  = tbl.get("select_cols", "*")
    cluster_keys = tbl.get("cluster_keys")
    track_del    = tbl.get("track_deletes", "Y")
    last_ct      = int(tbl["last_ct_version"])

    fq_source    = f"[{schema_nm}].[{src_table}]"
    staged_name  = f"{target_table}_staged"
    seq_col      = seq_key if seq_key else "_ct_version"

    # ── Decide load mode ──────────────────────────────────────────────────
    is_incr = (tbl["load_mode"] == "incr"
               and last_ct > 0
               and last_ct < db_ct_version)
    ct_from = last_ct if is_incr else None

    # ── Build JDBC query ──────────────────────────────────────────────────
    if is_incr:
        if select_cols and select_cols.strip() != "*":
            data_cols = [f"t.[{c.strip()}]" for c in select_cols.split(",")]
        else:
            data_cols = ["t.*"]
        key_select  = ", ".join(f"ct.[{c}]" for c in keys)
        data_select = ", ".join(data_cols)
        jdbc_query = (
            f"SELECT ct.SYS_CHANGE_OPERATION AS _ct_op, "
            f"ct.SYS_CHANGE_VERSION AS _ct_version, "
            f"{key_select}, {data_select} "
            f"FROM CHANGETABLE(CHANGES {fq_source}, {ct_from}) AS ct "
            f"LEFT JOIN {fq_source} AS t ON "
            + " AND ".join(f"ct.[{c}] = t.[{c}]" for c in keys)
        )
    else:
        if select_cols and select_cols.strip() != "*":
            col_list   = ", ".join(f"[{c.strip()}]" for c in select_cols.split(","))
            jdbc_query = f"SELECT {col_list} FROM {fq_source}"
        else:
            jdbc_query = f"SELECT * FROM {fq_source}"

    # ── Step 1: @dp.temporary_view — JDBC read from SQL Server ────────────
    @dp.temporary_view(name=staged_name)
    def staged_view(q=jdbc_query, incr=is_incr, ct_ver=db_ct_version):
        if incr:
            df = jdbc_read(spark, source, q)
        else:
            df = jdbc_read(spark, source, q)
            df = (df.withColumn("_ct_op", lit("I"))
                    .withColumn("_ct_version", lit(ct_ver)))
        return df

    # ── Step 2: dp.create_streaming_table — silver target ─────────────────
    create_kw = {
        "name":    target_table,
        "comment": f"SCD Type {scd_type} — {src_table} → {target_schema}",
    }
    if cluster_keys and cluster_keys.strip():
        create_kw["cluster_by"] = [c.strip() for c in cluster_keys.split(",")]

    dp.create_streaming_table(**create_kw)

    # ── Step 3: dp.create_auto_cdc_flow — SCD1 or SCD2 ───────────────────
    cdc_kw = {
        "target":              target_table,
        "source":              staged_name,
        "keys":                keys,
        "sequence_by":         col(seq_col),
        "stored_as_scd_type":  scd_type,
        "except_column_list":  ["_ct_op", "_ct_version"],
    }
    if track_del == "Y":
        cdc_kw["apply_as_deletes"] = col("_ct_op") == "D"

    dp.create_auto_cdc_flow(**cdc_kw)

    mode_label = "INCR" if is_incr else "FULL"
    print(f"  ✓ {fq_source} → {target_table}  "
          f"({mode_label}, SCD{scd_type}, keys={keys})")

print(f"\nSDP pipeline: {len(table_configs)} tables declared")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Post-pipeline: update CT versions in Lakebase
# MAGIC
# MAGIC SDP calls this after all tables are processed successfully.

# COMMAND ----------

for tbl in table_configs:
    execute(client_schema=client_name, sql="""
        UPDATE table_config
           SET last_ct_version = %s,
               last_status     = 'SUCCESS',
               update_dttm     = now()
         WHERE src_schema_nm = %s AND src_tbl_nm = %s
    """, params=(db_ct_version, tbl["src_schema_nm"], tbl["src_tbl_nm"]))

print(f"Lakebase updated: {len(table_configs)} tables → CT version {db_ct_version}")