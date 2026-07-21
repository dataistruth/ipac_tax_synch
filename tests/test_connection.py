# =============================================================================
# tests/test_connections.py — Standalone connection validation
# No bundle required — all config hardcoded inline.
#
# Run in Databricks notebook:
#   copy-paste entire file into a cell and run
# =============================================================================

import traceback
import psycopg2
import psycopg2.extras

# ── Config ────────────────────────────────────────────────────────────────────

SQLSERVER_SOURCE = {
    "jdbc_url": (
        "jdbc:sqlserver://test-data-deloitte.database.windows.net:1433;"
        "database=free-sql-db-0862313;"
        "encrypt=true;trustServerCertificate=false;"
        "hostNameInCertificate=*.database.windows.net;loginTimeout=30"
    ),
    "username": "CloudSAf8ffff73",
    "password": "NewPassword123@##",
}

SQLSERVER_TARGET = SQLSERVER_SOURCE

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

# ── SQL Server tests ──────────────────────────────────────────────────────────

def test_sqlserver_source(spark):
    name = "SQL Server — Source (JDBC)"
    try:
        df = (spark.read.format("jdbc")
                .option("url",      SQLSERVER_SOURCE["jdbc_url"])
                .option("user",     SQLSERVER_SOURCE["username"])
                .option("password", SQLSERVER_SOURCE["password"])
                .option("query",    "SELECT @@VERSION AS version, DB_NAME() AS db")
                .option("driver",   "com.microsoft.sqlserver.jdbc.SQLServerDriver")
                .load())
        row = df.first()
        _pass(name, f"db={row['db']}  |  {str(row['version'])[:70]}...")
        return True
    except Exception:
        _fail(name)
        return False


def test_sqlserver_target(spark):
    name = "SQL Server — Target (JDBC)"
    try:
        df = (spark.read.format("jdbc")
                .option("url",      SQLSERVER_TARGET["jdbc_url"])
                .option("user",     SQLSERVER_TARGET["username"])
                .option("password", SQLSERVER_TARGET["password"])
                .option("query",    "SELECT @@VERSION AS version, DB_NAME() AS db")
                .option("driver",   "com.microsoft.sqlserver.jdbc.SQLServerDriver")
                .load())
        row = df.first()
        _pass(name, f"db={row['db']}  |  {str(row['version'])[:70]}...")
        return True
    except Exception:
        _fail(name)
        return False

# ── Lakebase tests ────────────────────────────────────────────────────────────

def test_lakebase_psycopg2():
    name = "Lakebase — psycopg2"
    try:
        conn = psycopg2.connect(
            host           = LAKEBASE["host"],
            port           = LAKEBASE["port"],
            dbname         = LAKEBASE["database"],
            user           = LAKEBASE["username"],
            password       = LAKEBASE["password"],
            sslmode        = "require",
            cursor_factory = psycopg2.extras.RealDictCursor,
        )
        with conn.cursor() as cur:
            cur.execute("SELECT version(), current_database() AS db;")
            row = cur.fetchone()
        conn.close()
        _pass(name, f"db={row['db']}  |  {str(row['version'])[:60]}...")
        return True
    except Exception:
        _fail(name)
        return False


def test_lakebase_jdbc(spark):
    name = "Lakebase — JDBC (Spark)"
    try:
        jdbc_url = (
            f"jdbc:postgresql://{LAKEBASE['host']}:{LAKEBASE['port']}"
            f"/{LAKEBASE['database']}?sslmode=require"
        )
        df = (spark.read.format("jdbc")
                .option("url",      jdbc_url)
                .option("user",     LAKEBASE["username"])
                .option("password", LAKEBASE["password"])
                .option("query",    "SELECT version() AS version, current_database() AS db")
                .option("driver",   "org.postgresql.Driver")
                .load())
        row = df.first()
        _pass(name, f"db={row['db']}  |  {str(row['version'])[:60]}...")
        return True
    except Exception:
        _fail(name)
        return False


def test_lakebase_schema():
    name = "Lakebase — Client schema"
    try:
        schema = LAKEBASE["schema"]
        conn   = psycopg2.connect(
            host           = LAKEBASE["host"],
            port           = LAKEBASE["port"],
            dbname         = LAKEBASE["database"],
            user           = LAKEBASE["username"],
            password       = LAKEBASE["password"],
            sslmode        = "require",
            cursor_factory = psycopg2.extras.RealDictCursor,
        )
        with conn.cursor() as cur:
            cur.execute(
                "SELECT schema_name FROM information_schema.schemata WHERE schema_name = %s;",
                (schema,)
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
    except Exception:
        _fail(name)
        return False

# ── Run all ───────────────────────────────────────────────────────────────────

def run_all_tests(spark):
    print("=" * 60)
    print(" Connection Tests — client_a (standalone / no bundle)")
    print("=" * 60)
    print()
    print(" [ SQL Server ]")
    ss = test_sqlserver_source(spark)
    st = test_sqlserver_target(spark)
    print()
    print(" [ Lakebase ]")
    lp = test_lakebase_psycopg2()
    lj = test_lakebase_jdbc(spark)
    ls = test_lakebase_schema()

    passed = sum([ss, st, lp, lj, ls])
    print()
    print("=" * 60)
    print(f" Summary: {passed}/5 passed  {'✅ ALL GOOD' if passed == 5 else '⚠️  CHECK FAILURES ABOVE'}")
    print("=" * 60)

run_all_tests(spark)