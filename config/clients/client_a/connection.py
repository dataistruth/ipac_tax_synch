# =============================================================================
# Client A — Connection Configuration
# Credentials: Databricks secret scope (see config/setup_secrets.sh)
# =============================================================================

SECRET_SCOPE = "client-a-secrets"

CONNECTION = {

    "secret_scope": SECRET_SCOPE,

    # ── Source SQL Server (read) ──────────────────────────────────────────────
    "source": {
        "host":     "test-data-deloitte.database.windows.net",
        "port":     1433,
        "database": "free-sql-db-0862313",
        "schema":   "dbo",
        "secret_scope": SECRET_SCOPE,
        "secret_keys": {
            "username": "source-username",
            "password": "source-password",
        },
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
        "secret_scope": SECRET_SCOPE,
        "secret_keys": {
            "username": "target-username",
            "password": "target-password",
        },
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
