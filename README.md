# OpenAlgo Mini FOSS Universe

A fully restorable Docker-based deployment of the OpenAlgo Mini trading terminal, deployable on any VPS with GitHub as the single source of truth.

**zerotouchalgo.com** — powered by Cloudflare

---

## Quick Restore (after cloning)

```bash
# 1. Clone the repo
git clone https://github.com/zerotouchalgo/foss-universe.git
cd foss-universe

# 2. Decrypt secrets (requires age key on VPS at ~/.config/sops/age/keys.txt)
./docker/scripts/decrypt.sh

# 3. Start everything
docker-compose up -d

# 4. Verify
curl -I https://zerotouchalgo.com/nginx-health
```

That's it. One command after cloning.

---

## Architecture

```
                    ┌─────────────────────────────┐
                    │       Cloudflare             │
                    │   (zerotouchalgo.com)        │
                    │   Proxy enabled (orange)      │
                    └──────────────┬──────────────┘
                                   │ :443 (HTTPS)
                    ┌──────────────▼──────────────┐
                    │         nginx:1.27          │
                    │   Reverse proxy + SSL term  │
                    │   Rate limiting             │
                    └──┬──────────────┬───────────┘
                       │             │
              ┌────────▼──┐   ┌────▼────────────┐
              │  foss_    │   │  foss_universe  │
              │  redis    │   │  _container      │
              │  :6379    │   │  :8001 (Flask/   │
              │           │   │  Flask-SocketIO) │
              └───────────┘   └──────────────────┘
```

---

## Directory Structure

```
foss-universe/
├── app/
│   ├── backend/           # Python FastAPI + Flask-SocketIO
│   │   ├── Dockerfile
│   │   ├── server.py
│   │   ├── config.py
│   │   ├── requirements.txt
│   │   ├── start.sh
│   │   └── .env.example
│   └── frontend/         # React (builds into backend dist/)
│       ├── Dockerfile
│       ├── package.json
│       └── dist/
├── nginx/
│   ├── nginx.conf         # Main nginx config
│   └── conf.d/app.conf    # Site-level reverse proxy config
├── docker/
│   ├── .sops.yaml         # SOPS encryption config (age public key)
│   └── scripts/
│       ├── decrypt.sh     # Decrypt .env.enc → data/.env
│       ├── encrypt.sh     # .env → .env.enc (dev only)
│       └── update-dns.sh  # Cloudflare DDNS sidecar
├── data/                  # Created by decrypt.sh — gitignored
│   └── .env
├── ssl/                   # Cloudflare Origin Certificate — gitignored
│   ├── origin.pem
│   └── origin-key.pem
├── backups/               # Snapshot archives — gitignored
├── docker-compose.yml
├── .env.example          # Plain-text template (safe to commit)
├── .env.enc              # SOPS-encrypted secrets (in repo)
├── .gitignore
├── backup.sh             # Snapshot backup script
├── setup-sops.sh         # One-time VPS SOPS setup
└── README.md
```

---

## Security Model

Secrets are **never stored in plain text**.

1. `.env` contains broker API keys, Redis password, `APP_KEY`, etc.
2. `.env` is **gitignored** — never committed
3. `.env.enc` is the SOPS-encrypted version stored in the repo
4. The age **private key** lives only at `~/.config/sops/age/keys.txt` on the VPS
5. The age **public key** is in `docker/.sops.yaml`

**Encryption flow:**

```
data/.env  →[encrypt.sh + age]→  .env.enc  →[commit → GitHub]
                                           │
.gitignore ← data/.env  ←[decrypt.sh]──────┘
```

---

## Initial Setup (First Time)

### On the VPS:

```bash
# Install Docker + Docker Compose
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker ubuntu
# Log out and back in

# Install age + SOPS + generate keys
chmod +x setup-sops.sh
./setup-sops.sh
```

`setup-sops.sh` will:
- Install `age` and `sops`
- Generate `~/.config/sops/age/keys.txt`
- Print the **public key** — add it to `docker/.sops.yaml`

### On your dev machine:

```bash
# Clone the repo
git clone https://github.com/zerotouchalgo/foss-universe.git
cd foss-universe

# Copy the age private key from VPS (via password manager is best)
mkdir -p ~/.config/sops/age
scp ubuntu@your-vps:~/.config/sops/age/keys.txt ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# Create .env with real credentials
cp .env.example data/.env
nano data/.env   # fill in BROKER_API_KEY, BROKER_API_SECRET, APP_KEY, REDIS_PASSWORD

# Encrypt
chmod +x docker/scripts/encrypt.sh
./docker/scripts/encrypt.sh

# Commit and push
git add .env.enc docker/.sops.yaml docker-compose.yml nginx/ docker/ backup.sh
git commit -m "feat: add Docker deployment infrastructure"
git push origin main
```

### On the VPS (again):

```bash
git clone https://github.com/zerotouchalgo/foss-universe.git
cd foss-universe

# Create data directory structure
mkdir -p data/db data/log data/strategies data/keys data/tmp backups ssl

# Create SSL directory and install Cloudflare Origin Certificate
# (Download from: Cloudflare Dashboard → SSL/TLS → Origin Server)
# Upload origin.pem and origin-key.pem to ssl/
cp your-origin.pem ssl/origin.pem
cp your-origin-key.pem ssl/origin-key.pem
chmod 600 ssl/origin-key.pem

# Decrypt + start
./docker/scripts/decrypt.sh
docker-compose up -d
```

---

## Backup

```bash
./backup.sh                    # snapshot to ./backups/
./backup.sh --keep 7           # keep last 7 backups
./backup.sh --output /tmp/snapshot.tar.gz
./backup.sh --no-stop          # hot backup without stopping containers
```

Restore from a backup:

```bash
tar -xzf backups/foss-universe_YYYYMMDD_HHMMSS.tar.gz
./docker/scripts/decrypt.sh
docker-compose up -d
```

---

## Validation Checklist

- [ ] `nginx -t` — nginx config syntax valid
- [ ] `docker-compose config` — compose file valid
- [ ] `./docker/scripts/decrypt.sh` — `.env` created without errors
- [ ] `docker-compose up -d` — all containers start
- [ ] `docker-compose ps` — all containers healthy
- [ ] `curl -I https://zerotouchalgo.com/nginx-health` — 200 OK
- [ ] `curl -kf https://zerotouchalgo.com/auth/check-setup` — JSON response
- [ ] `docker-compose restart` — containers come back up
- [ ] `docker-compose down && docker-compose up -d` — data persists in `/home/ubuntu/foss-universe/`
- [ ] `./backup.sh` — snapshot created successfully

---

## Adding a New Secret

```bash
# 1. On dev machine: add to data/.env
echo "NEW_SECRET=value" >> data/.env

# 2. Encrypt and push
./docker/scripts/encrypt.sh
git add .env.enc && git commit -m "chore: add NEW_SECRET" && git push

# 3. On VPS: pull and decrypt
git pull
./docker/scripts/decrypt.sh
docker-compose up -d
```

---

## SOPS Workflow Summary

| Step | Location | Action |
|------|----------|--------|
| Generate keys | VPS | `./setup-sops.sh` |
| Update .sops.yaml | Dev machine | Add public key to `docker/.sops.yaml` |
| Create .env | Dev machine | Fill real credentials |
| Encrypt | Dev machine | `./docker/scripts/encrypt.sh` |
| Commit | Dev machine | `git add .env.enc && git commit && git push` |
| Clone | VPS | `git clone ...` |
| Decrypt | VPS | `./docker/scripts/decrypt.sh` |
| Start | VPS | `docker-compose up -d` |
