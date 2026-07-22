#!/bin/bash
# =============================================================================
# setup_secrets.sh — Register client credentials in a Databricks secret scope
#
# Prerequisites:
#   databricks auth login --profile <profile>
#
# Quick start (interactive):
#   ./config/setup_secrets.sh --scope client-a-secrets
#   ./config/setup_secrets.sh --profile prod_w --scope client-a-secrets
#
# Manual CLI (non-interactive example):
#   databricks secrets create-scope client-a-secrets --profile prod_w
#   databricks secrets put-secret client-a-secrets source-username   --string-value "CloudSAf8ffff73" --profile prod_w
#   databricks secrets put-secret client-a-secrets source-password   --string-value "<password>" --profile prod_w
#   databricks secrets put-secret client-a-secrets target-username   --string-value "CloudSAf8ffff73" --profile prod_w
#   databricks secrets put-secret client-a-secrets target-password   --string-value "<password>" --profile prod_w
#   databricks secrets put-secret client-a-secrets lakebase-username --string-value "client_a_app" --profile prod_w
#   databricks secrets put-secret client-a-secrets lakebase-password --string-value "<password>" --profile prod_w
#
# Verify:
#   databricks secrets list-scopes --profile prod_w
#   databricks secrets list-secrets client-a-secrets --profile prod_w
#
# Local dev (PyCharm / pytest) — export env vars instead:
#   export CLIENT_A_SECRETS__SOURCE_USERNAME=...
#   export CLIENT_A_SECRETS__SOURCE_PASSWORD=...
#   export CLIENT_A_SECRETS__TARGET_USERNAME=...
#   export CLIENT_A_SECRETS__TARGET_PASSWORD=...
#   export CLIENT_A_SECRETS__LAKEBASE_USERNAME=...
#   export CLIENT_A_SECRETS__LAKEBASE_PASSWORD=...
# =============================================================================

set -e

DEFAULT_PROFILE="prod_w"
DEFAULT_SCOPE="client-a-secrets"

PROFILE="$DEFAULT_PROFILE"
SCOPE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile) PROFILE="$2"; shift 2 ;;
        --scope)   SCOPE="$2";   shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

if [[ -z "$SCOPE" ]]; then
    SCOPE="$DEFAULT_SCOPE"
fi

if [[ -z "$PROFILE" ]]; then
    echo "ERROR: --profile cannot be empty."
    echo ""
    echo "Usage: ./config/setup_secrets.sh [--profile prod_w] [--scope client-a-secrets]"
    exit 1
fi

DB="databricks --profile $PROFILE"

echo ""
echo "Profile : $PROFILE"
echo "Scope   : $SCOPE"
echo ""

if $DB secrets list-scopes -o json 2>/dev/null | grep -q "\"name\"[[:space:]]*:[[:space:]]*\"$SCOPE\""; then
    echo "Secret scope '$SCOPE' already exists — skipping creation."
else
    $DB secrets create-scope "$SCOPE"
    echo "Secret scope '$SCOPE' created."
fi

echo ""
echo "Enter credentials (input is hidden for passwords):"
echo ""

read -p  "  Source SQL Server username   : " SOURCE_USERNAME
read -sp "  Source SQL Server password   : " SOURCE_PASSWORD && echo

read -p  "  Target SQL Server username   : " TARGET_USERNAME
read -sp "  Target SQL Server password   : " TARGET_PASSWORD && echo

read -p  "  Lakebase (Postgres) username : " LB_USERNAME
read -sp "  Lakebase (Postgres) password : " LB_PASSWORD && echo

echo ""
echo "Writing secrets to scope '$SCOPE'..."

$DB secrets put-secret "$SCOPE" "source-username"   --string-value "$SOURCE_USERNAME" && echo "  ✓ source-username"
$DB secrets put-secret "$SCOPE" "source-password"   --string-value "$SOURCE_PASSWORD" && echo "  ✓ source-password"
$DB secrets put-secret "$SCOPE" "target-username"   --string-value "$TARGET_USERNAME" && echo "  ✓ target-username"
$DB secrets put-secret "$SCOPE" "target-password"   --string-value "$TARGET_PASSWORD" && echo "  ✓ target-password"
$DB secrets put-secret "$SCOPE" "lakebase-username" --string-value "$LB_USERNAME"     && echo "  ✓ lakebase-username"
$DB secrets put-secret "$SCOPE" "lakebase-password" --string-value "$LB_PASSWORD"     && echo "  ✓ lakebase-password"

echo ""
echo "Registered secrets:"
$DB secrets list-secrets "$SCOPE"

echo ""
echo "Config files reference scope: $SCOPE"
echo "  config/base_config.py"
echo "  config/clients/client_a/connection.py"
