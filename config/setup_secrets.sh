#!/bin/bash
# =============================================================================
# setup_secrets.sh — Common secret registration script for ALL clients
# Run once per client per environment via Databricks CLI.
#
# Prerequisites:
#   - Databricks CLI installed and authenticated
#     https://docs.databricks.com/dev-tools/cli/databricks-cli.html
#
# Usage:
#   ./config/setup_secrets.sh --profile <cli_profile> --scope <scope_name>
#
# Examples:
#   ./config/setup_secrets.sh --profile dev   --scope client-a-secrets
#   ./config/setup_secrets.sh --profile prod  --scope client-b-secrets
#
# Secrets registered (prompted at runtime, never stored in this script):
#   source-username / source-password    ← source SQL Server
#   target-username / target-password    ← target SQL Server (write-back)
#   lakebase-username / lakebase-password ← Lakebase / Postgres
# =============================================================================

set -e

# ── Argument parsing ─────────────────────────────────────────────────────────
PROFILE=""
SCOPE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile) PROFILE="$2"; shift 2 ;;
        --scope)   SCOPE="$2";   shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

if [[ -z "$PROFILE" || -z "$SCOPE" ]]; then
    echo "ERROR: --profile and --scope are both required."
    echo ""
    echo "Usage: ./config/setup_secrets.sh --profile <cli_profile> --scope <scope_name>"
    echo ""
    echo "Examples:"
    echo "  ./config/setup_secrets.sh --profile dev  --scope client-a-secrets"
    echo "  ./config/setup_secrets.sh --profile prod --scope client-b-secrets"
    exit 1
fi

DB="databricks --profile $PROFILE"

# ── Create scope if it doesn't exist ─────────────────────────────────────────
echo ""
echo "Profile : $PROFILE"
echo "Scope   : $SCOPE"
echo ""

if $DB secrets list-scopes | grep -q "^$SCOPE"; then
    echo "Secret scope '$SCOPE' already exists — skipping creation."
else
    $DB secrets create-scope "$SCOPE"
    echo "Secret scope '$SCOPE' created."
fi

# ── Prompt for credentials ───────────────────────────────────────────────────
echo ""
echo "Enter credentials (input is hidden):"
echo ""

read -p  "  Source SQL Server username  : " SOURCE_USERNAME
read -sp "  Source SQL Server password  : " SOURCE_PASSWORD && echo

read -p  "  Target SQL Server username  : " TARGET_USERNAME
read -sp "  Target SQL Server password  : " TARGET_PASSWORD && echo

read -p  "  Lakebase (Postgres) username : " LB_USERNAME
read -sp "  Lakebase (Postgres) password : " LB_PASSWORD && echo

# ── Push secrets ─────────────────────────────────────────────────────────────
echo ""
echo "Writing secrets to scope '$SCOPE'..."

$DB secrets put-secret "$SCOPE" "source-username"   --string-value "$SOURCE_USERNAME" && echo "  ✓ source-username"
$DB secrets put-secret "$SCOPE" "source-password"   --string-value "$SOURCE_PASSWORD" && echo "  ✓ source-password"
$DB secrets put-secret "$SCOPE" "target-username"   --string-value "$TARGET_USERNAME" && echo "  ✓ target-username"
$DB secrets put-secret "$SCOPE" "target-password"   --string-value "$TARGET_PASSWORD" && echo "  ✓ target-password"
$DB secrets put-secret "$SCOPE" "lakebase-username" --string-value "$LB_USERNAME"     && echo "  ✓ lakebase-username"
$DB secrets put-secret "$SCOPE" "lakebase-password" --string-value "$LB_PASSWORD"     && echo "  ✓ lakebase-password"

# ── Verify ───────────────────────────────────────────────────────────────────
echo ""
echo "Registered secrets in scope '$SCOPE':"
$DB secrets list-secrets "$SCOPE" | awk 'NR>1 {print "  ✓", $1}'

echo ""
echo "Done. Ensure connection.py for this client has:"
echo "  \"akv_scope\": \"$SCOPE\""