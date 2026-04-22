#!/usr/bin/env bash
# =============================================================================
# setup-sops.sh — One-time SOPS + age setup on a fresh VPS
#
# Run ONCE on a new VPS to:
#   1. Install age
#   2. Generate age key pair
#   3. Print the PUBLIC key to add to docker/.sops.yaml
#   4. Install SOPS binary
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

KEY_DIR="$HOME/.config/sops/age"
KEY_PATH="$KEY_DIR/keys.txt"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --------------------------------------------------------------------------- #
# Step 1: Install age
# --------------------------------------------------------------------------- #
log_info "Installing age..."
if command -v age &>/dev/null; then
    log_warn "age already installed: $(age --version)"
else
    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y age
    elif command -v brew &>/dev/null; then
        brew install age
    else
        log_error "Unsupported package manager. Install age manually: https://github.com/FiloSottile/age"
        exit 1
    fi
    log_info "age installed: $(age --version)"
fi

# --------------------------------------------------------------------------- #
# Step 2: Generate age key pair
# --------------------------------------------------------------------------- #
log_info "Generating age key pair..."
mkdir -p "$KEY_DIR"

if [[ -f "$KEY_PATH" ]]; then
    log_warn "Key already exists at $KEY_PATH — will NOT overwrite."
else
    age-keygen -o "$KEY_PATH"
    chmod 600 "$KEY_PATH"
    log_info "Key generated and saved to $KEY_PATH"
fi

PUBLIC_KEY=$(age-keygen -y "$KEY_PATH" 2>/dev/null || echo "")

if [[ -z "$PUBLIC_KEY" ]]; then
    log_error "Failed to generate public key from $KEY_PATH"
    exit 1
fi

# --------------------------------------------------------------------------- #
# Step 3: Install SOPS
# --------------------------------------------------------------------------- #
log_info "Installing SOPS..."
if command -v sops &>/dev/null; then
    log_warn "sops already installed: $(sops --version)"
else
    SOPS_VERSION="3.8.1"
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  DEB_ARCH="amd64" ;;
        aarch64) DEB_ARCH="arm64" ;;
        *)       log_error "Unsupported arch: $ARCH"; exit 1 ;;
    esac

    curl -fsSL \
        "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops_${SOPS_VERSION}_${DEB_ARCH}.deb" \
        -o /tmp/sops.deb

    sudo dpkg -i /tmp/sops.deb || sudo apt-get install -f -y
    rm /tmp/sops.deb
    log_info "SOPS installed: $(sops --version)"
fi

# --------------------------------------------------------------------------- #
# Step 4: Print instructions
# --------------------------------------------------------------------------- #
echo ""
echo "============================================================"
echo "  SOPS + age setup complete!"
echo "============================================================"
echo ""
echo "  Public key (add this to docker/.sops.yaml):"
echo ""
echo -e "  ${CYAN}${PUBLIC_KEY}${NC}"
echo ""
echo "  Private key location: ${KEY_PATH}"
echo ""
echo "  Next steps:"
echo "  1. Add the public key above to docker/.sops.yaml"
echo "  2. On your dev machine, copy the private key:"
echo "       scp ubuntu@your-vps:~/.config/sops/age/keys.txt ~/.config/sops/age/keys.txt"
echo "  3. Create data/.env from .env.example with real credentials"
echo "  4. Run: ./docker/scripts/encrypt.sh"
echo "  5. Commit .env.enc to GitHub"
echo "============================================================"
echo ""

# --------------------------------------------------------------------------- #
# Step 5: Verify SOPS config exists
# --------------------------------------------------------------------------- #
SOPS_CONF="$REPO_ROOT/docker/.sops.yaml"
if [[ -f "$SOPS_CONF" ]] && grep -q "REPLACE_WITH_YOUR" "$SOPS_CONF"; then
    log_warn "docker/.sops.yaml still has placeholder. Update it with the public key above."
else
    log_info "docker/.sops.yaml configured"
fi

log_info "Run ./docker/scripts/decrypt.sh to decrypt .env.enc"
