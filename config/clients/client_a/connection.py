# =============================================================================
# Client A — Connection Configuration (DEMO / HARDCODED)
# TODO: move credentials to Databricks secret scope before prod
#       run: ./config/setup_secrets.sh --profile <p> --scope client-a-secrets
# =============================================================================

CONNECTION = {

    # ── Source SQL Server (read) ──────────────────────────────────────────────
    "source": {
        "host":     "test-data-deloitte.database.windows.net",
        "port":     1433,
        "database": "free-sql-db-0862313",
        "schema":   "dbo",
        "username": "CloudSAf8ffff73",
        "password": "NewPassword123@##",
        "jdbc_options": {
            "encrypt":                "true",
            "trustServerCertificate": "false",
            "hostNameInCertificate":  "*.database.windows.net",
            "loginTimeout":           "30",
        },
    },

    # ── Target SQL Server (write-back) ────────────────────────────────────────
    "target": {
        "host":     "test-data-deloitte.database.windows.net",
        "port":     1433,
        "database": "free-sql-db-0862313",
        "schema":         "dbo",
        "staging_schema": "stg",
        "username": "CloudSAf8ffff73",
        "password": "NewPassword123@##",
        "jdbc_options": {
            "encrypt":                "true",
            "trustServerCertificate": "false",
            "hostNameInCertificate":  "*.database.windows.net",
            "loginTimeout":           "30",
        },
    },

    # ── Lakebase — client schema only (host/db in base_config.py) ─────────────
    "lakebase": {
        "schema": "client_a",
    },
}