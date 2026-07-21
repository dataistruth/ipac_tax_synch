# Databricks notebook source
# MAGIC %md
# MAGIC # Silver Ingestion — DLT Pipeline
# MAGIC **Task 3** — Pure declarative. Reads from raw Delta → auto CDC → silver.
# MAGIC
# MAGIC 1. `@dlt.view` → `spark.readStream.table()` from raw
# MAGIC 2. `dlt.create_streaming_table` → silver target
# MAGIC 3. `dlt.apply_changes` → SCD Type 1 or 2

# COMMAND ----------

import sys
import dlt
from pyspark.sql.functions import col

client_name   = spark.conf.get("client_name")
catalog       = spark.conf.get("catalog")
raw_schema    = spark.conf.get("raw_schema")
target_schema = spark.conf.get("target_schema")

nb_path   = dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get()
repo_root = "/Workspace" + nb_path.rsplit("/src/", 1)[0]
if repo_root not in sys.path:
    sys.path.insert(0, repo_root)

from src.utils.lakebase.connection import fetch_all

print(f"Client: {client_name}")
print(f"Raw:    {catalog}.{raw_schema}")
print(f"Silver: {catalog}.{target_schema}")

# COMMAND ----------

table_configs = fetch_all(client_schema=client_name, sql="""
    SELECT src_tbl_nm, target_tbl_nm, primary_key,
           scd_type, sequence_key, cluster_keys, track_deletes
      FROM table_config
     WHERE is_active = 'Y'
     ORDER BY load_priority, src_tbl_nm
""")

print(f"Generating DLT objects for {len(table_configs)} tables")

# COMMAND ----------

for tbl in table_configs:
    target_table = tbl["target_tbl_nm"]
    keys         = [k.strip() for k in tbl["primary_key"].split(",")]
    scd_type     = int(tbl["scd_type"])
    seq_key      = tbl.get("sequence_key")
    cluster_keys = tbl.get("cluster_keys")
    track_del    = tbl.get("track_deletes", "Y")

    fq_raw       = f"{catalog}.{raw_schema}.{tbl['src_tbl_nm']}"
    staged_name  = f"{target_table}_staged"
    seq_col      = seq_key if seq_key else "_ct_version"

    # ── @dlt.view — streaming read from raw Delta ─────────────────────────
    @dlt.view(name=staged_name)
    def staged_view(raw=fq_raw):
        return spark.readStream.table(raw)

    # ── dlt.create_streaming_table — silver target ────────────────────────
    dlt.create_streaming_table(
        name    = target_table,
        comment = f"SCD Type {scd_type} — {tbl['src_tbl_nm']} → {target_schema}",
    )

    # ── dlt.apply_changes — SCD1 or SCD2 ─────────────────────────────────
    apply_kw = {
        "target":              target_table,
        "source":              staged_name,
        "keys":                keys,
        "sequence_by":         col(seq_col),
        "stored_as_scd_type":  scd_type,
        "except_column_list":  ["_ct_op", "_ct_version"],
    }
    if track_del == "Y":
        apply_kw["apply_as_deletes"] = col("_ct_op") == "D"

    dlt.apply_changes(**apply_kw)

    print(f"  ✓ {fq_raw} → {target_table} (SCD{scd_type}, keys={keys})")

print(f"\nDLT: {len(table_configs)} tables declared")