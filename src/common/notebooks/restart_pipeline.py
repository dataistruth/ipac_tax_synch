# Databricks notebook source
# MAGIC %md
# MAGIC # Restart Lakeflow / DLT Pipeline (graceful)
# MAGIC
# MAGIC Scheduled job notebook: receives `pipeline_id`, stops an active update if needed,
# MAGIC then starts a new pipeline update via the **Pipelines API** (`databricks-sdk`).
# MAGIC
# MAGIC **Parameters (widgets / job base_parameters):**
# MAGIC | Parameter | Default | Description |
# MAGIC |-----------|---------|-------------|
# MAGIC | `pipeline_config` | *(for_each)* | JSON: `name`, `pipeline_id`, `full_refresh` |
# MAGIC | `pipeline_id` | *(manual)* | Pipeline UUID when not using for_each |
# MAGIC | `full_refresh` | `false` | Full refresh on restart |
# MAGIC | `stop_timeout_seconds` | `600` | Max wait for stop to complete |
# MAGIC | `wait_for_update` | `false` | Wait until new update finishes |
# MAGIC
# MAGIC **Schedule:** attach to a Databricks job (no cluster required — serverless notebook or default).

# COMMAND ----------

dbutils.widgets.text("pipeline_config", "", "Pipeline config JSON")
dbutils.widgets.text("pipeline_id", "", "Pipeline ID")
dbutils.widgets.dropdown("full_refresh", "false", ["false", "true"], "Full refresh")
dbutils.widgets.text("stop_timeout_seconds", "600", "Stop timeout (sec)")
dbutils.widgets.dropdown("wait_for_update", "false", ["false", "true"], "Wait for update")

import json

pipeline_config_raw = dbutils.widgets.get("pipeline_config").strip()
pipeline_id = dbutils.widgets.get("pipeline_id").strip()
full_refresh = dbutils.widgets.get("full_refresh").strip().lower() == "true"
stop_timeout_seconds = int(dbutils.widgets.get("stop_timeout_seconds").strip() or "600")
wait_for_update = dbutils.widgets.get("wait_for_update").strip().lower() == "true"

if pipeline_config_raw:
    cfg = json.loads(pipeline_config_raw)
    pipeline_id = (cfg.get("pipeline_id") or "").strip()
    full_refresh = bool(cfg.get("full_refresh", full_refresh))
    pipeline_name_hint = cfg.get("name") or ""
else:
    pipeline_name_hint = ""

if not pipeline_id:
    raise ValueError("pipeline_id is required (set pipeline_config or pipeline_id)")

print(f"pipeline_name_hint  : {pipeline_name_hint or '(from API)'}")
print(f"pipeline_id          : {pipeline_id}")
print(f"full_refresh         : {full_refresh}")
print(f"stop_timeout_seconds : {stop_timeout_seconds}")
print(f"wait_for_update      : {wait_for_update}")

# COMMAND ----------

import time
from datetime import timedelta

from databricks.sdk import WorkspaceClient

w = WorkspaceClient()

# COMMAND ----------

ACTIVE_UPDATE_STATES = frozenset({
    "RUNNING",
    "QUEUED",
    "INITIALIZING",
    "WAITING_FOR_RESOURCES",
    "SETTING_UP_TABLES",
    "RESETTING",
})


def _latest_update(client, pid: str):
    resp = client.pipelines.list_updates(pipeline_id=pid, max_results=1)
    updates = resp.updates or []
    return updates[0] if updates else None


def _active_update_state(update):
    if update is None:
        return None
    state = update.state
    if state is None:
        return None
    return state.value if hasattr(state, "value") else str(state)


def graceful_restart(
    client: WorkspaceClient,
    pid: str,
    *,
    full_refresh: bool = False,
    stop_timeout_seconds: int = 600,
    wait_for_update: bool = False,
) -> dict:
    """Stop active update if any, then start a new update."""
    pipeline = client.pipelines.get(pipeline_id=pid)
    name = pipeline.name or pid
    continuous = bool(pipeline.spec and pipeline.spec.continuous)
    print(f"Pipeline name     : {name}")
    print(f"Continuous        : {continuous}")
    print(f"Pipeline state    : {pipeline.state}")

    latest = _latest_update(client, pid)
    latest_state = _active_update_state(latest)
    print(f"Latest update     : {latest.update_id if latest else 'none'}")
    print(f"Latest update state: {latest_state or 'none'}")

    if latest_state in ACTIVE_UPDATE_STATES:
        print("Active update detected — calling pipelines.stop (graceful cancel)...")
        client.pipelines.stop_and_wait(
            pipeline_id=pid,
            timeout=timedelta(seconds=stop_timeout_seconds),
        )
        print("Stop completed.")
    else:
        print("No active update — skip stop.")

    print("Starting new pipeline update...")
    start_resp = client.pipelines.start_update(
        pipeline_id=pid,
        full_refresh=full_refresh,
    )
    update_id = start_resp.update_id
    print(f"Started update_id : {update_id}")

    result = {
        "pipeline_id": pid,
        "pipeline_name": name,
        "continuous": continuous,
        "update_id": update_id,
        "full_refresh": full_refresh,
        "status": "STARTED",
    }

    if wait_for_update and update_id:
        print("Waiting for update to complete...")
        deadline = time.time() + stop_timeout_seconds
        while time.time() < deadline:
            info = client.pipelines.get_update(pipeline_id=pid, update_id=update_id)
            state = _active_update_state(info.update)
            print(f"  update state: {state}")
            if state not in ACTIVE_UPDATE_STATES:
                result["final_update_state"] = state
                result["status"] = state or "COMPLETED"
                break
            time.sleep(30)
        else:
            result["status"] = "TIMEOUT_WAITING"
            print("Timed out waiting for update to finish.")

    return result

# COMMAND ----------

outcome = graceful_restart(
    w,
    pipeline_id,
    full_refresh=full_refresh,
    stop_timeout_seconds=stop_timeout_seconds,
    wait_for_update=wait_for_update,
)

dbutils.notebook.exit(str(outcome))
