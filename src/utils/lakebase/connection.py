# =============================================================================
# src/utils/lakebase/connection.py
#
# Lakebase (PostgreSQL) connection helper.
# Host/port/database from config/base_config.py; credentials from secret scope.
# =============================================================================

import psycopg2
import psycopg2.extras
from config.base_config import BASE_CONFIG
from src.utils.secrets import get_credentials


def get_connection(client_schema: str = None, dbutils=None):
    """
    Returns a psycopg2 connection to Lakebase.

    Args:
        client_schema : if set, search_path is pinned (e.g. 'client_a')
        dbutils       : optional; auto-detected in Databricks notebooks
    """
    lb = BASE_CONFIG["lakebase"]
    creds = get_credentials(lb, dbutils=dbutils)

    conn = psycopg2.connect(
        host            = lb["host"],
        port            = lb["port"],
        dbname          = lb["database"],
        user            = creds["username"],
        password        = creds["password"],
        sslmode         = "require",
        cursor_factory  = psycopg2.extras.RealDictCursor,
        connect_timeout = 10,
    )

    if client_schema:
        with conn.cursor() as cur:
            cur.execute(f"SET search_path TO {client_schema}, public;")
        conn.commit()

    return conn


def fetch_all(client_schema: str, sql: str, params=None, dbutils=None) -> list[dict]:
    """Convenience: connect, query, return list of dicts, close."""
    with get_connection(client_schema, dbutils=dbutils) as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            return [dict(row) for row in cur.fetchall()]


def execute(client_schema: str, sql: str, params=None, dbutils=None):
    """Convenience: connect, execute (INSERT/UPDATE/DELETE), commit, close."""
    with get_connection(client_schema, dbutils=dbutils) as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
        conn.commit()
