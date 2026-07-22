# =============================================================================
# tests/test_connections_local.py — Run from PyCharm / local IDE
# Requires env vars (see config/setup_secrets.sh) — no hardcoded passwords.
#
# Run:
#   export CLIENT_A_SECRETS__LAKEBASE_USERNAME=...
#   export CLIENT_A_SECRETS__LAKEBASE_PASSWORD=...
#   python tests/test_connections_local.py
# =============================================================================

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import traceback

import psycopg2
import psycopg2.extras

from config.base_config import BASE_CONFIG
from src.utils.secrets import SecretNotFoundError, get_credentials

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
    lb = BASE_CONFIG["lakebase"]
    creds = get_credentials(lb)
    return psycopg2.connect(
        host            = lb["host"],
        port            = lb["port"],
        dbname          = lb["database"],
        user            = creds["username"],
        password        = creds["password"],
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
    except SecretNotFoundError as exc:
        print(f"  ⚠️  SKIP  {name}")
        print(f"           {exc}")
        return False
    except Exception:
        _fail(name)
        return False


def test_lakebase_schema():
    name = "Lakebase — schema exists"
    schema = "client_a"
    try:
        conn = _get_connection()
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
        print(f"  ⚠️  WARN  {name}")
        print(f"           Schema '{schema}' not found")
        return False
    except SecretNotFoundError as exc:
        print(f"  ⚠️  SKIP  {name}")
        print(f"           {exc}")
        return False
    except Exception:
        _fail(name)
        return False


def run_all_tests():
    print()
    print("=" * 60)
    print(" Local Connection Tests (secrets via env vars)")
    print("=" * 60)
    print()

    results = {
        "Connection": test_lakebase_connection(),
        "Schema    ": test_lakebase_schema(),
    }

    passed = sum(results.values())
    total = len(results)

    print()
    print("=" * 60)
    print(f" Summary: {passed}/{total} passed")
    print("=" * 60)
    print()


if __name__ == "__main__":
    run_all_tests()
