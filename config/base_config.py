# =============================================================================
# config/base_config.py — Shared defaults inherited by all clients
# =============================================================================

BASE_CONFIG = {

    # ── Lakebase (Neon Postgres) ──────────────────────────────────────────────
    # Shared instance — one schema per client (e.g. client_a, client_b)
    # DEMO: credentials hardcoded — move to Databricks secret scope for prod
    "lakebase": {
        "host":     "ep-late-silence-e9u5p1s2.database.eastus.azuredatabricks.net",
        "port":     5432,
        "database": "ipac_control_db",
        "username": "ipac_user",
        "password": "Ipac@Tax2026!",
        "jdbc_options": {
            "sslmode": "require",
        },
        # TODO prod: replace username/password with secret scope references
        # "akv_scope":   "ipac-lakebase-secrets",
        # "secret_keys": {"username": "lakebase-username", "password": "lakebase-password"},
    },

    # ── Databricks / Unity Catalog ────────────────────────────────────────────
    "catalog":           "main",
    "raw_schema_prefix": "raw_",

    # ── Pipeline defaults ─────────────────────────────────────────────────────
    "batch_size":        10_000,
    "jdbc_fetch_size":   5_000,
    "retry": {
        "max_attempts":    3,
        "backoff_seconds": 30,
    },
}