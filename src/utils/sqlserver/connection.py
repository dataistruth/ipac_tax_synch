# =============================================================================
# src/utils/sqlserver/connection.py
#
# Two connection methods:
#   pymssql  → lightweight, pure Python, for metadata / CT version queries
#   JDBC     → Spark distributed reads, for bulk data unload
#
# Credentials resolved via src.utils.secrets (Databricks scope or env vars).
# =============================================================================

from src.utils.secrets import resolve_conn_block


def _resolved(connection_source: dict, dbutils=None) -> dict:
    return resolve_conn_block(connection_source, dbutils=dbutils)


# =============================================================================
# pymssql — lightweight queries (CT versions, row counts, metadata)
# =============================================================================

def get_connection(connection_source: dict, dbutils=None):
    """
    Lightweight pymssql connection for metadata queries.
    No Spark, no JVM — direct TCP to SQL Server.
    """
    import pymssql

    src = _resolved(connection_source, dbutils)
    return pymssql.connect(
        server       = src["host"],
        port         = src["port"],
        user         = src["username"],
        password     = src["password"],
        database     = src["database"],
        tds_version  = "7.3",
        login_timeout = 30,
    )


def fetch_one(connection_source: dict, sql: str, params=None, dbutils=None) -> dict:
    """Single row query — CT version checks, scalar lookups."""
    with get_connection(connection_source, dbutils=dbutils) as conn:
        cursor = conn.cursor(as_dict=True)
        cursor.execute(sql, params)
        return cursor.fetchone()


def fetch_all(connection_source: dict, sql: str, params=None, dbutils=None) -> list[dict]:
    """Multi-row query — metadata, small lookups."""
    with get_connection(connection_source, dbutils=dbutils) as conn:
        cursor = conn.cursor(as_dict=True)
        cursor.execute(sql, params)
        return cursor.fetchall()


# =============================================================================
# Spark JDBC — bulk data reads (full table / CHANGETABLE deltas)
# =============================================================================

def get_jdbc_config(connection_source: dict, dbutils=None) -> tuple[str, dict]:
    """
    Build JDBC URL + Spark properties from CONNECTION["source"].

    Returns:
        (jdbc_url, jdbc_props)
    """
    src = _resolved(connection_source, dbutils)

    jdbc_url = (
        f"jdbc:sqlserver://{src['host']}:{src['port']};"
        f"databaseName={src['database']};"
        + ";".join(f"{k}={v}" for k, v in src["jdbc_options"].items())
    )

    jdbc_props = {
        "user":     src["username"],
        "password": src["password"],
        "driver":   "com.microsoft.sqlserver.jdbc.SQLServerDriver",
    }

    return jdbc_url, jdbc_props


def jdbc_read(spark, connection_source: dict, query: str, dbutils=None):
    """
    Pushdown query via Spark JDBC — use for bulk data unload.

    Returns a Spark DataFrame.
    """
    jdbc_url, jdbc_props = get_jdbc_config(connection_source, dbutils=dbutils)
    return (
        spark.read.format("jdbc")
        .option("url", jdbc_url)
        .options(**jdbc_props)
        .option("query", query)
        .load()
    )


def jdbc_read_table(spark, connection_source: dict, query: str,
                    partition_col: str = None, num_partitions: int = None,
                    fetch_size: int = 10000, dbutils=None):
    """
    Partitioned JDBC read for medium/large tables.
    """
    jdbc_url, jdbc_props = get_jdbc_config(connection_source, dbutils=dbutils)

    reader = (
        spark.read.format("jdbc")
        .option("url", jdbc_url)
        .options(**jdbc_props)
        .option("fetchsize", str(fetch_size))
    )

    if partition_col and num_partitions and num_partitions > 1:
        bounds_df = jdbc_read(
            spark, connection_source,
            f"SELECT MIN([{partition_col}]) AS lo, "
            f"MAX([{partition_col}]) AS hi FROM ({query}) _b",
            dbutils=dbutils,
        )
        bounds = bounds_df.first()
        if bounds and bounds["lo"] is not None:
            return (
                reader
                .option("dbtable", f"({query}) _t")
                .option("partitionColumn", partition_col)
                .option("lowerBound", str(bounds["lo"]))
                .option("upperBound", str(bounds["hi"]))
                .option("numPartitions", str(num_partitions))
                .load()
            )

    return reader.option("query", query).load()