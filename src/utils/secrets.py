# =============================================================================
# secrets.py — Credential resolution
#
# DEMO MODE : reads credentials directly from connection config (hardcoded)
# PROD MODE : swap get_credentials() to read from Databricks secret scope:
#               dbutils.secrets.get(scope=scope, key=key)
# =============================================================================

from __future__ import annotations


def get_credentials(conn_block: dict, dbutils=None) -> dict[str, str]:
    """
    Return username + password from the connection block.

    DEMO: reads hardcoded values directly.
    PROD: replace body with dbutils.secrets.get() calls.

    Args:
        conn_block : source or target block from CONNECTION config
        dbutils    : not used in demo mode, kept for prod signature compatibility
    """
    return {
        "username": conn_block["username"],
        "password": conn_block["password"],
    }


def build_jdbc_url(conn_block: dict, dbutils=None) -> tuple[str, str, str]:
    """
    Build SQL Server JDBC URL + credentials.

    Returns:
        (jdbc_url, username, password)

    Example
    -------
    from config.clients.client_a.connection import CONNECTION
    from src.utils.secrets import build_jdbc_url

    jdbc_url, user, pwd = build_jdbc_url(CONNECTION["source"])

    df = (spark.read.format("jdbc")
            .option("url",      jdbc_url)
            .option("user",     user)
            .option("password", pwd)
            .option("dbtable",  "dbo.orders")
            .load())
    """
    creds   = get_credentials(conn_block, dbutils)
    opts    = conn_block.get("jdbc_options", {})
    host    = conn_block["host"]
    port    = conn_block["port"]
    db      = conn_block["database"]

    opt_str  = ";".join(f"{k}={v}" for k, v in opts.items())
    jdbc_url = f"jdbc:sqlserver://{host}:{port};database={db};{opt_str}"

    return jdbc_url, creds["username"], creds["password"]