#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

if [ ! -d ".venv" ]; then
  echo "Creating virtual environment..."
  python3 -m venv .venv
fi

source .venv/bin/activate
pip install -r requirements.txt -q

if [ ! -f ".env" ]; then
  cp .env.example .env
  echo "Created .env from .env.example — please configure your broker API credentials"
fi

echo "Starting FOSS Universe backend on port 8001..."
exec gunicorn server:app \
  --bind "0.0.0.0:8001" \
  --worker-class eventlet \
  --workers 2 \
  --threads 4 \
  --timeout 120 \
  --keep-alive 30 \
  --access-logfile - \
  --error-logfile - \
  --log-level info
