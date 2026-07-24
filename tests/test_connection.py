# =============================================================================
# tests/test_connection.py — Connection validation in Databricks
#
# Credentials: Databricks secret scope `client-a-secrets` (no hardcoded passwords).
# Register secrets first:
#   ./config/setup_secrets.sh --profile <profile> --scope client-a-secrets
#
# Run in a Databricks notebook (repo attached) or copy-paste into a cell.
# Requires: spark, dbutils
# =============================================================================

import os
import sys
import traceback

import psycopg2
import psycopg2.extras

# ── Repo path (Databricks notebook or local) ──────────────────────────────────

try:
    nb_path = dbutils.notebook.entry_point.getDbutils().notebook().getContext().notebookPath().get()
    repo_root = "/Workspace" + nb_path.rsplit("/tests/", 1)[0]
except NameError:
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

if repo_root not in sys.path:
    sys.path.insert(0, repo_root)

from config.base_config import BASE_CONFIG
from config.clients.client_a.connection import CONNECTION
from src.utils.lakebase.connection import get_connection as get_lakebase_connection
from src.utils.secrets import SecretNotFoundError, get_credentials
from src.utils.sqlserver.connection import jdbc_read

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


def _skip(name, exc):
    print(f"  ⚠️  SKIP  {name}")
    print(f"           {exc}")


def _lakebase_creds(dbutils=None):
    lb = BASE_CONFIG["lakebase"]
    creds = get_credentials(lb, dbutils=dbutils)
    return lb, creds


# ── SQL Server tests ──────────────────────────────────────────────────────────

def test_sqlserver_source(spark, dbutils=None):
    name = "SQL Server — Source (JDBC)"
    try:
        df = jdbc_read(
            spark,
            CONNECTION["source"],
            "SELECT @@VERSION AS version, DB_NAME() AS db",
            dbutils=dbutils,
        )
        row = df.first()
        _pass(name, f"db={row['db']}  |  {str(row['version'])[:70]}...")
        return True
    except SecretNotFoundError as exc:
        _skip(name, exc)
        return False
    except Exception:
        _fail(name)
        return False


def test_sqlserver_target(spark, dbutils=None):
    name = "SQL Server — Target (JDBC)"
    try:
        df = jdbc_read(
            spark,
            CONNECTION["target"],
            "SELECT @@VERSION AS version, DB_NAME() AS db",
            dbutils=dbutils,
        )
        row = df.first()
        _pass(name, f"db={row['db']}  |  {str(row['version'])[:70]}...")
        return True
    except SecretNotFoundError as exc:
        _skip(name, exc)
        return False
    except Exception:
        _fail(name)
        return False


# ── Lakebase tests ────────────────────────────────────────────────────────────

def test_lakebase_psycopg2(dbutils=None):
    name = "Lakebase — psycopg2"
    try:
        conn = get_lakebase_connection(dbutils=dbutils)
        with conn.cursor() as cur:
            cur.execute("SELECT version(), current_database() AS db;")
            row = cur.fetchone()
        conn.close()
        _pass(name, f"db={row['db']}  |  {str(row['version'])[:60]}...")
        return True
    except SecretNotFoundError as exc:
        _skip(name, exc)
        return False
    except Exception:
        _fail(name)
        return False


def test_lakebase_jdbc(spark, dbutils=None):
    name = "Lakebase — JDBC (Spark)"
    try:
        lb, creds = _lakebase_creds(dbutils)
        jdbc_url = (
            f"jdbc:postgresql://{lb['host']}:{lb['port']}"
            f"/{lb['database']}?sslmode=require"
        )
        df = (spark.read.format("jdbc")
                .option("url", jdbc_url)
                .option("user", creds["username"])
                .option("password", creds["password"])
                .option("query", "SELECT version() AS version, current_database() AS db")
                .option("driver", "org.postgresql.Driver")
                .load())
        row = df.first()
        _pass(name, f"db={row['db']}  |  {str(row['version'])[:60]}...")
        return True
    except SecretNotFoundError as exc:
        _skip(name, exc)
        return False
    except Exception:
        _fail(name)
        return False


def test_lakebase_schema(dbutils=None):
    name = "Lakebase — Client schema"
    schema = CONNECTION["lakebase"]["schema"]
    try:
        conn = get_lakebase_connection(client_schema=schema, dbutils=dbutils)
        with conn.cursor() as cur:
            cur.execute(
                "SELECT schema_name FROM information_schema.schemata WHERE schema_name = %s;",
                (schema,),
            )
            exists = cur.fetchone()
            if not exists:
                cur.execute(f"CREATE SCHEMA IF NOT EXISTS {schema};")
                conn.commit()
                _pass(name, f"Schema '{schema}' created ✓")
            else:
                _pass(name, f"Schema '{schema}' already exists ✓")
        conn.close()
        return True
    except SecretNotFoundError as exc:
        _skip(name, exc)
        return False
    except Exception:
        _fail(name)
        return False


# ── Run all ───────────────────────────────────────────────────────────────────

def run_all_tests(spark, dbutils=None):
    print("=" * 60)
    print(" Connection Tests — client_a (secrets via client-a-secrets)")
    print("=" * 60)
    print()
    print(" [ SQL Server ]")
    ss = test_sqlserver_source(spark, dbutils=dbutils)
    st = test_sqlserver_target(spark, dbutils=dbutils)
    print()
    print(" [ Lakebase ]")
    lp = test_lakebase_psycopg2(dbutils=dbutils)
    lj = test_lakebase_jdbc(spark, dbutils=dbutils)
    ls = test_lakebase_schema(dbutils=dbutils)

    passed = sum([ss, st, lp, lj, ls])
    print()
    print("=" * 60)
    print(f" Summary: {passed}/5 passed  {'✅ ALL GOOD' if passed == 5 else '⚠️  CHECK FAILURES ABOVE'}")
    print("=" * 60)


if "spark" in dir():
    run_all_tests(spark, dbutils=dbutils)
