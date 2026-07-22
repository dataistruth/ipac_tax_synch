# =============================================================================
# config/base_config.py — Shared defaults inherited by all clients
# Credentials: Databricks secret scope (see config/setup_secrets.sh)
# =============================================================================

SECRET_SCOPE = "client-a-secrets"

BASE_CONFIG = {

    # ── Lakebase (Neon Postgres) ──────────────────────────────────────────────
    "lakebase": {
        "host":     "ep-divine-flower-d2b43f3x.database.us-east-1.cloud.databricks.com",
        "port":     5432,
        "database": "databricks_postgres",
        "secret_scope": SECRET_SCOPE,
        "secret_keys": {
            "username": "lakebase-username",
            "password": "lakebase-password",
        },
    },

    # ── Databricks / Unity Catalog ────────────────────────────────────────────
    "catalog":           "ipac_tax_synch",
    "dest_catalog":      "ipac_tax_synch",
    "raw_schema_prefix": "raw_",

    # ── Pipeline defaults ─────────────────────────────────────────────────────
    "batch_size":        10_000,
    "jdbc_fetch_size":   5_000,
    "retry": {
        "max_attempts":    3,
        "backoff_seconds": 30,
    },
}
