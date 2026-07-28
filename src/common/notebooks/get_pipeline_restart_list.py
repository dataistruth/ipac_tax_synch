# Databricks notebook source
# MAGIC %md
# MAGIC # Get Pipeline List (shared)
# MAGIC Reads `config/common/pipeline_restart_registry.json` for job `for_each` tasks.
# MAGIC
# MAGIC | `list_mode` | Filter (JSON config only) |
# MAGIC |-------------|---------------------------|
# MAGIC | `restart` | `do_restart=Y` and `pipeline_id` set |
# MAGIC
# MAGIC For stop checks use `check_config_pipeline_stop_status.py` (reads `check_for_stop=Y` from the same JSON).

# COMMAND ----------

import json
import os
import sys

dbutils.widgets.dropdown("list_mode", "restart", ["restart"], "List mode")

list_mode = dbutils.widgets.get("list_mode").strip().lower()
if list_mode != "restart":
    raise ValueError("list_mode must be restart (use check_config_pipeline_stop_status for stop checks)")

print(f"list_mode: {list_mode}")

# COMMAND ----------

nb_path = dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get()
repo_root = "/Workspace" + nb_path.rsplit("/src/", 1)[0]
if repo_root not in sys.path:
    sys.path.insert(0, repo_root)
print(f"repo_root: {repo_root}")

# COMMAND ----------

registry_path = os.path.join(repo_root, "config", "common", "pipeline_restart_registry.json")
with open(registry_path, encoding="utf-8") as f:
    registry = json.load(f)


def _is_yes(value) -> bool:
    if isinstance(value, bool):
        return value
    return str(value).strip().upper() in ("Y", "YES", "TRUE", "1")


pipelines = []
for entry in registry.get("pipelines") or []:
    pipeline_id = (entry.get("pipeline_id") or "").strip()
    if not pipeline_id:
        continue

    if not _is_yes(entry.get("do_restart", "N")):
        continue

    pipelines.append({
        "name": entry.get("name") or pipeline_id,
        "pipeline_id": pipeline_id,
        "full_refresh": bool(entry.get("full_refresh", False)),
        "do_restart": entry.get("do_restart", "N"),
        "check_for_stop": entry.get("check_for_stop", "N"),
        "notes": entry.get("notes") or "",
    })

if not pipelines:
    raise ValueError(
        f"No pipelines for restart. Set do_restart=Y and pipeline_id in {registry_path}."
    )

print(f"Found {len(pipelines)} pipeline(s) for {list_mode}:")
for p in pipelines:
    print(f"  - {p['name']} ({p['pipeline_id']})")

# COMMAND ----------

dbutils.jobs.taskValues.set(key="pipelines", value=json.dumps(pipelines))
