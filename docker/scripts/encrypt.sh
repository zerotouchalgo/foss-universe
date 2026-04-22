#!/usr/bin/env bash
# =============================================================================
# encrypt.sh — Encrypts data/.env → .env.enc using SOPS + age
#
# FOR DEVELOPMENT / INITIAL SETUP ONLY.
# Never run this with real credentials on an untrusted machine.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOPS_CONF="$REPO_ROOT/docker/.sops.yaml"
ENV_IN="$REPO_ROOT/data/.env"
ENV_ENC="$REPO_ROOT/.env.enc"
AGE_KEY_PATH="${AGE_KEY_PATH:-$HOME/.config/sops/age/keys.txt}"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

if [[ ! -f "$ENV_IN" ]]; then
    log_error ".env not found at $ENV_IN — create it from .env.example first"
    exit 1
fi

if [[ ! -f "$SOPS_CONF" ]]; then
    log_error "SOPS config not found: $SOPS_CONF"
    exit 1
fi

export SOPSAGEKEYFILE="$AGE_KEY_PATH"

log_info "Encrypting $ENV_IN → $ENV_ENC ..."
sops --config "$SOPS_CONF" encrypt --output "$ENV_ENC" "$ENV_IN"

chmod 644 "$ENV_ENC"
log_info "Encrypted file written: $ENV_ENC ($(wc -c < "$ENV_ENC") bytes)"
