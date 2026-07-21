# =============================================================================
# tests/test_connections_local.py — Run from PyCharm / local IDE
# Tests Lakebase (psycopg2) only — no Spark/dbutils needed.
#
# Run:
#   python tests/test_connections_local.py
# =============================================================================

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import traceback
import psycopg2
import psycopg2.extras

# ── Config ────────────────────────────────────────────────────────────────────

LAKEBASE = {
    "host":     "ep-late-silence-e9u5p1s2.database.eastus.azuredatabricks.net",
    "port":     5432,
    "database": "ipac_control_db",
    "username": "ipac_user",
    "password": "Ipac@Tax2026!",
    "schema":   "client_a",
}

# ── helpers ───────────────────────────────────────────────────────────────────

def _pass(name, detail=""):
    print(f"  ✅ PASS  {name}")
    if detail:
        print(f"           {detail}")

def _fail(name):
    lines = traceback.format_exc().strip().splitlines()
    print(f"  ❌ FAIL  {name}")
    for line in lines[-3:]:
        print(f"           {line.strip()}")

def _get_connection():
    return psycopg2.connect(
        host            = LAKEBASE["host"],
        port            = LAKEBASE["port"],
        dbname          = LAKEBASE["database"],
        user            = LAKEBASE["username"],
        password        = LAKEBASE["password"],
        sslmode         = "require",
        cursor_factory  = psycopg2.extras.RealDictCursor,
        connect_timeout = 10,
    )

# ── Tests ─────────────────────────────────────────────────────────────────────

def test_lakebase_connection():
    name = "Lakebase — basic connection"
    try:
        conn = _get_connection()
        with conn.cursor() as cur:
            cur.execute("SELECT version(), current_database() AS db, current_user AS usr;")
            row = cur.fetchone()
        conn.close()
        _pass(name,
            f"db={row['db']}  user={row['usr']}\n"
            f"           pg={str(row['version'])[:60]}..."
        )
        return True
    except Exception:
        _fail(name)
        return False


def test_lakebase_schema():
    name = "Lakebase — schema exists"
    try:
        schema = LAKEBASE["schema"]
        conn   = _get_connection()
        with conn.cursor() as cur:
            cur.execute(
                "SELECT nspname FROM pg_catalog.pg_namespace WHERE nspname = %s;",
                (schema,)
            )
            row = cur.fetchone()
        conn.close()
        if row:
            _pass(name, f"Schema '{schema}' found ✓")
            return True
        else:
            print(f"  ⚠️  WARN  {name}")
            print(f"           Schema '{schema}' not found — run CREATE SCHEMA in Lakebase SQL editor")
            return False
    except Exception:
        _fail(name)
        return False


def test_lakebase_write():
    name = "Lakebase — write + read (smoke test)"
    try:
        schema = LAKEBASE["schema"]
        conn   = _get_connection()
        with conn.cursor() as cur:
            cur.execute(f"""
                CREATE TABLE IF NOT EXISTS {schema}.connection_test (
                    id        SERIAL PRIMARY KEY,
                    test_key  TEXT NOT NULL,
                    tested_at TIMESTAMPTZ DEFAULT NOW()
                );
            """)
            cur.execute(
                f"INSERT INTO {schema}.connection_test (test_key) VALUES (%s) RETURNING id;",
                ("local_pycharm_test",)
            )
            inserted_id = cur.fetchone()["id"]
            cur.execute(
                f"SELECT * FROM {schema}.connection_test WHERE id = %s;",
                (inserted_id,)
            )
            row = cur.fetchone()
            conn.commit()
            cur.execute(
                f"DELETE FROM {schema}.connection_test WHERE id = %s;",
                (inserted_id,)
            )
            conn.commit()
        conn.close()
        _pass(name, f"Inserted id={inserted_id}  key={row['test_key']}  at={row['tested_at']} ✓")
        return True
    except Exception:
        _fail(name)
        return False


def test_lakebase_permissions():
    name = "Lakebase — user permissions"
    try:
        schema = LAKEBASE["schema"]
        conn   = _get_connection()
        with conn.cursor() as cur:
            cur.execute("""
                SELECT has_schema_privilege(%s, %s, 'USAGE') AS can_usage,
                       has_schema_privilege(%s, %s, 'CREATE') AS can_create;
            """, (LAKEBASE["username"], schema, LAKEBASE["username"], schema))
            row = cur.fetchone()
        conn.close()
        privs = []
        if row["can_usage"]:  privs.append("USAGE")
        if row["can_create"]: privs.append("CREATE")
        _pass(name, f"User '{LAKEBASE['username']}' on schema '{schema}': {', '.join(privs)} ✓")
        return True
    except Exception:
        _fail(name)
        return False


# ── Run all ───────────────────────────────────────────────────────────────────

def run_all_tests():
    print()
    print("=" * 60)
    print(" Local Connection Tests (PyCharm / no Spark)")
    print(" Target: Lakebase (psycopg2 only)")
    print("=" * 60)
    print()
    print(" [ Lakebase ]")

    results = {
        "Connection ": test_lakebase_connection(),
        "Schema     ": test_lakebase_schema(),
        "Write/Read ": test_lakebase_write(),
        "Permissions": test_lakebase_permissions(),
    }

    passed = sum(results.values())
    total  = len(results)

    print()
    print("=" * 60)
    print(f" Summary: {passed}/{total} passed  {'✅ ALL GOOD' if passed == total else '⚠️  CHECK FAILURES ABOVE'}")
    print()
    print(" NOTE: SQL Server JDBC tests require Spark — run")
    print("       tests/test_connections.py in a Databricks notebook.")
    print("=" * 60)
    print()


if __name__ == "__main__":
    run_all_tests()