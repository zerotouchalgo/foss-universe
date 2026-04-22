#!/usr/bin/env bash
# =============================================================================
# decrypt.sh — Decrypts .env.enc → data/.env using SOPS + age
#
# PREREQUISITES (must be installed on VPS):
#   1. age    :  sudo apt install age
#   2. sops   :  https://github.com/getsops/sops/releases
#   3. Age key:  ~/.config/sops/age/keys.txt (generated once, never committed)
#
# USAGE:
#   ./decrypt.sh                    # decrypt .env.enc → data/.env
#   ./decrypt.sh --check            # verify .env.enc exists
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOPS_CONF="$REPO_ROOT/docker/.sops.yaml"
ENV_ENC="$REPO_ROOT/.env.enc"
ENV_OUT="$REPO_ROOT/data/.env"
AGE_KEY_PATH="${AGE_KEY_PATH:-$HOME/.config/sops/age/keys.txt}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# --------------------------------------------------------------------------- #
# Verify prerequisites
# --------------------------------------------------------------------------- #
verify_prereqs() {
    local missing=0

    if ! command -v sops &>/dev/null; then
        log_error "sops not found. Run ./setup-sops.sh or install from:"
        log_error "  https://github.com/getsops/sops/releases"
        missing=1
    fi
    if ! command -v age &>/dev/null; then
        log_error "age not found. Run: sudo apt install age"
        missing=1
    fi
    if [[ ! -f "$AGE_KEY_PATH" ]]; then
        log_error "Age key not found at: $AGE_KEY_PATH"
        log_error "Generate with: age-keygen -o ~/.config/sops/age/keys.txt"
        missing=1
    fi
    if [[ ! -f "$SOPS_CONF" ]]; then
        log_error "SOPS config not found: $SOPS_CONF"
        missing=1
    fi
    if [[ ! -f "$ENV_ENC" ]]; then
        log_error "Encrypted file not found: $ENV_ENC"
        missing=1
    fi

    (( missing )) && return 1
    return 0
}

# --------------------------------------------------------------------------- #
# Main: decrypt
# --------------------------------------------------------------------------- #
decrypt() {
    log_info "Decrypting secrets..."
    log_info "  Source : $ENV_ENC"
    log_info "  Dest   : $ENV_OUT"
    log_info "  Key    : $AGE_KEY_PATH"

    # Create data/ directory if it does not exist
    mkdir -p "$(dirname "$ENV_OUT")"

    # Export age key path for sops
    export SOPSAGEKEYFILE="$AGE_KEY_PATH"

    # Decrypt using SOPS
    sops --config "$SOPS_CONF" decrypt --output "$ENV_OUT" "$ENV_ENC"

    local exit_code=$?
    if (( exit_code == 0 )); then
        local size
        size=$(wc -c < "$ENV_OUT")
        chmod 600 "$ENV_OUT"
        log_info "Decryption successful: $ENV_OUT (${size} bytes)"
    else
        log_error "Decryption failed with exit code: $exit_code"
        return $exit_code
    fi
}

# --------------------------------------------------------------------------- #
# CLI entrypoint
# --------------------------------------------------------------------------- #
case "${1:-}" in
    --check)
        if [[ ! -f "$ENV_ENC" ]]; then
            log_error ".env.enc not found at $ENV_ENC"
            exit 1
        fi
        log_info ".env.enc found"
        exit 0
        ;;
    --help|-h)
        echo "Usage: $0 [--check|--help]"
        echo "  (no args)  Decrypt .env.enc → data/.env"
        echo "  --check    Verify .env.enc exists"
        echo "  --help     Show this help"
        exit 0
        ;;
    *)
        verify_prereqs || exit 1
        decrypt
        ;;
esac
