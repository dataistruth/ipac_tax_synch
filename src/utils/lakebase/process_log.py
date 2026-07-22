# =============================================================================
# src/utils/lakebase/process_log.py
#
# Helpers for writing rows to client process_log in Lakebase.
# =============================================================================

from datetime import datetime, timezone

from src.utils.lakebase.connection import execute

MAX_LOG_MESSAGE_LEN = 100
MAX_LOAD_MODE_LEN = 10


def truncate_log_message(message: str | None, max_len: int = MAX_LOG_MESSAGE_LEN) -> str | None:
    """Return message truncated to max_len characters for process_log storage."""
    if not message:
        return message
    return message[:max_len]


def normalize_load_mode(load_mode: str | None) -> str | None:
    """Map notebook/load values to process_log.load_mode ('full'|'incr', varchar(10))."""
    if not load_mode:
        return load_mode
    normalized = load_mode.strip().lower()
    if normalized in ("incremental", "incr"):
        return "incr"
    if normalized == "full":
        return "full"
    return normalized[:MAX_LOAD_MODE_LEN]


def write_process_log(
    *,
    client_schema: str,
    job_id: str,
    task_id: str,
    object_nm: str,
    status: str,
    task_type: str = "ingress",
    message: str | None = None,
    load_mode: str | None = None,
    ct_version_to: int | None = None,
    rows_written: int | None = None,
    dbutils=None,
) -> None:
    """Insert a row into the client process_log table in Lakebase."""
    now = datetime.now(timezone.utc)
    execute(
        client_schema=client_schema,
        dbutils=dbutils,
        sql="""
            INSERT INTO process_log
                (job_id, task_id, task_type, object_nm, load_mode,
                 ct_version_to, rows_written, error_message,
                 start_time, end_time, status)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """,
        params=(
            job_id,
            task_id,
            task_type,
            object_nm,
            normalize_load_mode(load_mode),
            ct_version_to,
            rows_written,
            truncate_log_message(message),
            now,
            now,
            status,
        ),
    )
