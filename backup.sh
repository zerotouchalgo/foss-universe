#!/usr/bin/env bash
# =============================================================================
# backup.sh — Creates a timestamped tar.gz snapshot of the foss-universe
#             deployment directory.
#
# USAGE:
#   ./backup.sh                       # Creates backup in ./backups/
#   ./backup.sh --output /path/file   # Custom output path
#   ./backup.sh --keep 7              # Retain last N backups (default: 14)
#   ./backup.sh --no-stop             # Skip container stop (hot backup)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="${DEPLOY_DIR:-$SCRIPT_DIR}"
BACKUP_DIR="${BACKUP_DIR:-$DEPLOY_DIR/backups}"
RETENTION="${RETENTION:-14}"
NO_STOP="${NO_STOP:-0}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

# --------------------------------------------------------------------------- #
# Parse args
# --------------------------------------------------------------------------- #
while (( $# )); do
    case "$1" in
        --output) OUTPUT_PATH="$2"; shift 2 ;;
        --keep)   RETENTION="$2"; shift 2 ;;
        --no-stop) NO_STOP=1; shift ;;
        *)        echo "[ERROR] Unknown argument: $1" >&2; exit 1 ;;
    esac
done

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
HOSTNAME=$(hostname -f 2>/dev/null || hostname)
BACKUP_NAME="foss-universe_${TIMESTAMP}.tar.gz"

if [[ -z "${OUTPUT_PATH:-}" ]]; then
    mkdir -p "$BACKUP_DIR"
    OUTPUT_PATH="$BACKUP_DIR/$BACKUP_NAME"
fi

log_info "Backup snapshot at $TIMESTAMP"
log_info "Source: $DEPLOY_DIR"
log_info "Output: $OUTPUT_PATH"

# --------------------------------------------------------------------------- #
# Stop containers gracefully (skip with --no-stop for hot backup)
# --------------------------------------------------------------------------- #
if (( ! NO_STOP )); then
    COMPOSE_FILE="$DEPLOY_DIR/docker-compose.yml"
    if [[ -f "$COMPOSE_FILE" ]] && docker-compose -f "$COMPOSE_FILE" ps -q &>/dev/null; then
        log_info "Stopping containers gracefully..."
        (cd "$DEPLOY_DIR" && docker-compose stop) || true
        WAS_RUNNING=1
    fi
fi

# --------------------------------------------------------------------------- #
# Create snapshot
# --------------------------------------------------------------------------- #
EXCLUDE_ARGS=(
    --exclude='*.tar.gz'
    --exclude='*.log'
    --exclude='backups/'
    --exclude='.git/'
    --exclude='node_modules/'
    --exclude='__pycache__/'
    --exclude='.venv/'
    --exclude='venv/'
    --exclude='*.pyc'
    --exclude='.cache/'
    --exclude='.npm/'
    --exclude='tmp/numba_cache/'
    --exclude='tmp/matplotlib/'
    --exclude='.claude/'
    --exclude='app/frontend/node_modules/'
    --exclude='app/backend/.venv/'
)

log_info "Creating tar archive..."
tar -czf "$OUTPUT_PATH" \
    -C "$DEPLOY_DIR" \
    "${EXCLUDE_ARGS[@]}" \
    --transform="s|^|foss-universe/|S" \
    .

BACKUP_SIZE=$(du -h "$OUTPUT_PATH" | cut -f1)
log_info "Snapshot created: $OUTPUT_PATH ($BACKUP_SIZE)"

# --------------------------------------------------------------------------- #
# Restart containers
# --------------------------------------------------------------------------- #
if [[ "${WAS_RUNNING:-0}" == "1" ]]; then
    log_info "Restarting containers..."
    (cd "$DEPLOY_DIR" && docker-compose start) || true
fi

# --------------------------------------------------------------------------- #
# Retention cleanup
# --------------------------------------------------------------------------- #
if [[ -d "$BACKUP_DIR" ]]; then
    count=$(ls -1t "$BACKUP_DIR"/foss-universe_*.tar.gz 2>/dev/null | wc -l)
    if (( count > RETENTION )); then
        log_info "Applying retention (keep last $RETENTION, removing $((count - RETENTION)))..."
        ls -1t "$BACKUP_DIR"/foss-universe_*.tar.gz 2>/dev/null \
            | tail -n +$((RETENTION + 1)) \
            | xargs -r rm -f
    fi
fi

log_info "Latest backup: $OUTPUT_PATH"

# --------------------------------------------------------------------------- #
# Optional: push to GitHub Releases
# --------------------------------------------------------------------------- #
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    log_info "Uploading to GitHub Releases..."
    gh release create "backup-${TIMESTAMP}" \
        --title "Backup ${TIMESTAMP}" \
        --notes "Automated backup snapshot from ${HOSTNAME}" \
        "$OUTPUT_PATH" \
        --clobber \
        || log_warn "GitHub release upload failed (non-fatal)"
fi

echo ""
echo "Backup complete: $OUTPUT_PATH"
