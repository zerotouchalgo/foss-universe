#!/usr/bin/env bash
# =============================================================================
# update-dns.sh — Cloudflare DDNS updater (runs as a sidecar container)
# Keeps the zerotouchalgo.com A record pointed at the VPS public IP.
# =============================================================================

set -euo pipefail

CF_API_TOKEN="${CF_API_TOKEN:?CF_API_TOKEN is required}"
CF_ZONE_ID="${CF_ZONE_ID:?CF_ZONE_ID is required}"
RECORD_NAME="${RECORD_NAME:-zerotouchalgo.com}"
RECORD_TYPE="${RECORD_TYPE:-A}"
CHECK_INTERVAL="${CHECK_INTERVAL:-300}"

get_public_ip() {
    curl -s --max-time 10 https://api.ipify.org \
        || curl -s --max-time 10 https://ifconfig.me \
        || curl -s --max-time 10 https://icanhazip.com
}

get_record_ip() {
    curl -s --max-time 10 \
        -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
        -H "Authorization: Bearer ${CF_API_TOKEN}" \
        -H "Content-Type: application/json" \
        | python3 -c "
import sys, json
data = json.load(sys.stdin)
for r in data.get('result', []):
    if r['name'] == '$RECORD_NAME' and r['type'] == '$RECORD_TYPE':
        print(r['content'])
        break
" 2>/dev/null || echo ""
}

update_dns() {
    local ip="$1"
    local record_id
    record_id=$(curl -s --max-time 10 \
        -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
        -H "Authorization: Bearer ${CF_API_TOKEN}" \
        -H "Content-Type: application/json" \
        | python3 -c "
import sys, json
data = json.load(sys.stdin)
for r in data.get('result', []):
    if r['name'] == '$RECORD_NAME' and r['type'] == '$RECORD_TYPE':
        print(r['id'])
        break
" 2>/dev/null || echo "")

    if [[ -z "$record_id" ]]; then
        echo "[DDNS] Creating new DNS record: ${RECORD_NAME} → ${ip}"
        curl -s --max-time 10 \
            -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
            -H "Authorization: Bearer ${CF_API_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "{\"type\":\"${RECORD_TYPE}\",\"name\":\"${RECORD_NAME}\",\"content\":\"${ip}\",\"proxied\":true}" \
            | python3 -c "import sys,json; d=json.load(sys.stdin); print('Created' if d.get('success') else 'Error: '+str(d))"
    else
        echo "[DDNS] Updating DNS record: ${RECORD_NAME} → ${ip}"
        curl -s --max-time 10 \
            -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${record_id}" \
            -H "Authorization: Bearer ${CF_API_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "{\"type\":\"${RECORD_TYPE}\",\"name\":\"${RECORD_NAME}\",\"content\":\"${ip}\",\"proxied\":true}" \
            | python3 -c "import sys,json; d=json.load(sys.stdin); print('Updated' if d.get('success') else 'Error: '+str(d))"
    fi
}

echo "[DDNS] Starting Cloudflare DDNS updater for ${RECORD_NAME}"
echo "[DDNS] Check interval: ${CHECK_INTERVAL}s"

while true; do
    current_ip=$(get_public_ip)
    record_ip=$(get_record_ip)

    if [[ -z "$current_ip" ]]; then
        echo "[DDNS] Failed to fetch public IP, retrying in 30s..."
        sleep 30
        continue
    fi

    if [[ "$current_ip" != "$record_ip" ]]; then
        echo "[DDNS] IP changed: ${record_ip:-none} → ${current_ip}"
        update_dns "$current_ip"
    else
        echo "[DDNS] IP unchanged: ${current_ip}"
    fi

    sleep "$CHECK_INTERVAL"
done
