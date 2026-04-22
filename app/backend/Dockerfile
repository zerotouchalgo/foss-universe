# app/backend/Dockerfile
# Multi-stage build for foss-universe backend

# ---------------------------- Python Builder Stage ---------------------------- #
FROM python:3.12-bullseye AS python-builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl build-essential && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./

RUN pip install --no-cache-dir uv && \
    uv venv .venv && \
    uv pip install --upgrade pip && \
    uv pip install -r requirements.txt && \
    rm -rf /root/.cache

# ---------------------------- Production Stage ------------------------------ #
FROM python:3.12-slim-bullseye AS production

# Runtime deps + timezone
RUN apt-get update && apt-get install -y --no-install-recommends \
    tzdata curl \
    libopenblas0 libgomp1 libgfortran5 && \
    ln -fs /usr/share/zoneinfo/Asia/Kolkata /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Non-root user for security
RUN useradd --create-home --uid 1000 appuser

WORKDIR /app

# Copy venv + app sources
COPY --from=python-builder --chown=appuser:appuser /app/.venv /app/.venv
COPY --chown=appuser:appuser . .

# Create required directories
RUN mkdir -p /app/log /app/db /app/tmp \
    /app/tmp/numba_cache /app/tmp/matplotlib \
    /app/strategies /app/strategies/scripts /app/strategies/examples \
    /app/keys && \
    chown -R appuser:appuser /app && \
    chmod -R 755 /app/strategies /app/log /app/tmp && \
    chmod 700 /app/keys && \
    touch /app/.env && \
    chown appuser:appuser /app/.env && chmod 666 /app/.env

# Fix CRLF from Windows line endings
COPY --chown=appuser:appuser start.sh /app/start.sh
RUN sed -i 's/\r$//' /app/start.sh && chmod +x /app/start.sh

# Runtime env vars
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TZ=Asia/Kolkata \
    TMPDIR=/app/tmp \
    NUMBA_CACHE_DIR=/app/tmp/numba_cache \
    LLVMLITE_TMPDIR=/app/tmp \
    MPLCONFIGDIR=/app/tmp/matplotlib \
    OPENBLAS_NUM_THREADS=2 \
    OMP_NUM_THREADS=2 \
    MKL_NUM_THREADS=2 \
    NUMEXPR_NUM_THREADS=2 \
    NUMBA_NUM_THREADS=2

USER appuser

EXPOSE 8001

CMD ["/app/start.sh"]
