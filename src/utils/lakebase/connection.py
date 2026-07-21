# =============================================================================
# src/common/utils/lakebase/connection.py
#
# Lakebase (PostgreSQL) connection helper.
# Host, port, database, username, password come from config/base_config.py.
# Auth: direct username/password (dbutils.credentials.getToken() does NOT
#       work for Lakebase — confirmed during testing).
# =============================================================================

import psycopg2
import psycopg2.extras
from config.base_config import BASE_CONFIG


def get_connection(client_schema: str = None):
    """
    Returns a psycopg2 connection to Lakebase (ipac_control_db).
    No dbutils needed — credentials come from BASE_CONFIG.

    Args:
        client_schema  : if set, search_path is pinned so queries skip
                         schema prefix  (e.g. 'client_a')

    Usage:
        with get_connection("client_a") as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT * FROM table_config WHERE is_active = 'Y'")
                rows = [dict(r) for r in cur.fetchall()]
    """
    lb = BASE_CONFIG["lakebase"]

    conn = psycopg2.connect(
        host            = lb["host"],
        port            = lb["port"],
        dbname          = lb["database"],
        user            = lb["username"],
        password        = lb["password"],
        sslmode         = "require",
        cursor_factory  = psycopg2.extras.RealDictCursor,
        connect_timeout = 10,
    )

    if client_schema:
        with conn.cursor() as cur:
            cur.execute(f"SET search_path TO {client_schema}, public;")
        conn.commit()

    return conn


def fetch_all(client_schema: str, sql: str, params=None) -> list[dict]:
    """Convenience: connect, query, return list of dicts, close."""
    with get_connection(client_schema) as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            return [dict(row) for row in cur.fetchall()]


def execute(client_schema: str, sql: str, params=None):
    """Convenience: connect, execute (INSERT/UPDATE/DELETE), commit, close."""
    with get_connection(client_schema) as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
        conn.commit()