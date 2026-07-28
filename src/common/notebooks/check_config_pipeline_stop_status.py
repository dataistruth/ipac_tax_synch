# Databricks notebook source
# MAGIC %md
# MAGIC # Check pipeline stop status (JSON config only)
# MAGIC Reads **only** `config/common/pipeline_restart_registry.json` entries with
# MAGIC `check_for_stop=Y` and `pipeline_id` set. Does **not** scan all workspace pipelines.
# MAGIC
# MAGIC Job fails and sends **on_failure** email if **any** configured pipeline is not `RUNNING`.

# COMMAND ----------

import json
import os
import sys

# COMMAND ----------

nb_path = dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get()
repo_root = "/Workspace" + nb_path.rsplit("/src/", 1)[0]
if repo_root not in sys.path:
    sys.path.insert(0, repo_root)

registry_path = os.path.join(repo_root, "config", "common", "pipeline_restart_registry.json")
with open(registry_path, encoding="utf-8") as f:
    registry = json.load(f)


def _is_yes(value) -> bool:
    if isinstance(value, bool):
        return value
    return str(value).strip().upper() in ("Y", "YES", "TRUE", "1")


# Only pipelines explicitly marked in JSON — not a workspace-wide list
pipelines = []
for entry in registry.get("pipelines") or []:
    if not _is_yes(entry.get("check_for_stop", "N")):
        continue
    pipeline_id = (entry.get("pipeline_id") or "").strip()
    if not pipeline_id:
        continue
    pipelines.append({
        "name": entry.get("name") or pipeline_id,
        "pipeline_id": pipeline_id,
        "notes": entry.get("notes") or "",
    })

if not pipelines:
    raise ValueError(
        f"No pipelines to check. Set check_for_stop=Y and pipeline_id in {registry_path}"
    )

print(f"Config check_for_stop=Y: {len(pipelines)} pipeline(s)")
for p in pipelines:
    print(f"  - {p['name']} ({p['pipeline_id']})")

# COMMAND ----------

from databricks.sdk import WorkspaceClient

RUNNING_STATES = frozenset({"RUNNING"})

w = WorkspaceClient()
stopped = []
running = []

for cfg in pipelines:
    pipeline_id = cfg["pipeline_id"]
    name = cfg["name"]

    pipeline = w.pipelines.get(pipeline_id=pipeline_id)
    state_str = (
        pipeline.state.value if hasattr(pipeline.state, "value")
        else str(pipeline.state or "UNKNOWN")
    )

    print(f"  {name}: state={state_str}")

    if state_str in RUNNING_STATES:
        running.append({**cfg, "state": state_str})
    else:
        stopped.append({
            **cfg,
            "state": state_str,
            "api_name": pipeline.name or name,
        })

# COMMAND ----------

print()
print(f"RUNNING ({len(running)}): {[p['name'] for p in running]}")
print(f"STOPPED ({len(stopped)}): {[p['name'] for p in stopped]}")

if stopped:
    lines = [
        "Lakeflow pipeline STOP alert (check_for_stop=Y entries in JSON config only)",
        f"Checked: {len(pipelines)} pipeline(s) | Stopped: {len(stopped)}",
        "",
        "Stopped pipelines:",
    ]
    for i, p in enumerate(stopped, 1):
        lines.append(
            f"  {i}. name={p['name']}"
        )
        lines.append(f"     state={p['state']}")
        lines.append(f"     pipeline_id={p['pipeline_id']}")
        if p.get("api_name") and p["api_name"] != p["name"]:
            lines.append(f"     api_name={p['api_name']}")
        if p.get("notes"):
            lines.append(f"     notes={p['notes']}")
        lines.append("")
    lines.append(f"Registry: {registry_path}")
    lines.append("Action: Workflows → Pipelines → verify status, or run restart job.")

    alert_message = "\n".join(lines)
    print(alert_message)
    raise RuntimeError(alert_message)

print("All configured pipelines are RUNNING.")
dbutils.notebook.exit(json.dumps({
    "checked_from_config": len(pipelines),
    "running": len(running),
    "stopped": 0,
    "stopped_pipelines": [],
}))
