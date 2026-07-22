# =============================================================================
# secrets.py — Credential resolution from Databricks secret scopes
#
# Databricks: dbutils.secrets.get(scope, key)
# Local dev : environment variables  {SCOPE}__{KEY}  (uppercase, dashes → _)
#             e.g. CLIENT_A_SECRETS__SOURCE_PASSWORD
# =============================================================================

from __future__ import annotations

import os
from typing import Any


class SecretNotFoundError(RuntimeError):
    """Raised when a required secret is missing in Databricks and locally."""


def _get_dbutils():
    """Return Databricks dbutils when running inside a notebook/job."""
    try:
        from pyspark.dbutils import DBUtils
        from pyspark.sql import SparkSession

        spark = SparkSession.getActiveSession()
        if spark is not None:
            return DBUtils(spark)
    except Exception:
        pass

    try:
        import IPython
        ip = IPython.get_ipython()
        if ip is not None:
            return ip.user_ns.get("dbutils")
    except Exception:
        pass

    return None


def _env_key(scope: str, key: str) -> str:
    return f"{scope.upper().replace('-', '_')}__{key.upper().replace('-', '_')}"


def get_secret(scope: str, key: str, dbutils: Any = None) -> str:
    """
    Read a secret from Databricks scope, falling back to env var for local runs.

    Local env var format: CLIENT_A_SECRETS__SOURCE_PASSWORD
    """
    if not scope or not key:
        raise ValueError("scope and key are required")

    if dbutils is None:
        dbutils = _get_dbutils()

    if dbutils is not None:
        return dbutils.secrets.get(scope=scope, key=key)

    env_name = _env_key(scope, key)
    value = os.environ.get(env_name)
    if value is not None:
        return value

    raise SecretNotFoundError(
        f"Secret '{scope}/{key}' not found. "
        f"In Databricks, run config/setup_secrets.sh. "
        f"Locally, export {env_name}=<value>"
    )


def get_credentials(
    conn_block: dict,
    dbutils: Any = None,
    secret_scope: str | None = None,
) -> dict[str, str]:
    """Resolve username/password from secret scope or inline config (legacy)."""
    scope = conn_block.get("secret_scope") or secret_scope
    keys = conn_block.get("secret_keys")

    if scope and keys:
        return {
            "username": get_secret(scope, keys["username"], dbutils),
            "password": get_secret(scope, keys["password"], dbutils),
        }

    username = conn_block.get("username")
    password = conn_block.get("password")
    if username and password:
        return {"username": username, "password": password}

    raise SecretNotFoundError(
        "Connection block has no secret_scope/secret_keys and no inline username/password"
    )


def resolve_conn_block(
    conn_block: dict,
    dbutils: Any = None,
    secret_scope: str | None = None,
) -> dict:
    """Return a copy of conn_block with username/password resolved from secrets."""
    resolved = dict(conn_block)
    creds = get_credentials(conn_block, dbutils=dbutils, secret_scope=secret_scope)
    resolved["username"] = creds["username"]
    resolved["password"] = creds["password"]
    return resolved


def resolve_connection(connection: dict, dbutils: Any = None) -> dict:
    """Resolve source/target credentials on a client CONNECTION dict."""
    scope = connection.get("secret_scope")
    resolved = dict(connection)

    if "source" in connection:
        resolved["source"] = resolve_conn_block(
            connection["source"], dbutils=dbutils, secret_scope=scope
        )
    if "target" in connection:
        resolved["target"] = resolve_conn_block(
            connection["target"], dbutils=dbutils, secret_scope=scope
        )
    return resolved


def build_jdbc_url(
    conn_block: dict,
    dbutils: Any = None,
    secret_scope: str | None = None,
) -> tuple[str, str, str]:
    """
    Build SQL Server JDBC URL + credentials.

    Returns:
        (jdbc_url, username, password)
    """
    src = resolve_conn_block(conn_block, dbutils=dbutils, secret_scope=secret_scope)
    opts = src.get("jdbc_options", {})
    host = src["host"]
    port = src["port"]
    db = src["database"]

    opt_str = ";".join(f"{k}={v}" for k, v in opts.items())
    jdbc_url = f"jdbc:sqlserver://{host}:{port};database={db};{opt_str}"

    return jdbc_url, src["username"], src["password"]
