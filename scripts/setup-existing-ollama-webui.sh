#!/usr/bin/env bash
# Reference script for EXISTING Ubuntu + Ollama installation.
# This script DOES NOT partition or format disks.
set -Eeuo pipefail
DATA="${LLM_DATA_DIR:-/mnt/llm-data}"
WEB_PORT="${WEBUI_PORT:-3000}"
MODELS="$DATA/ollama"
WEBUI="$DATA/open-webui"
DROPIN=/etc/systemd/system/ollama.service.d/override.conf

die(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }
say(){ printf '\n== %s ==\n' "$*"; }
[[ $EUID -eq 0 ]] || die "Run with sudo bash $0"
command -v ollama >/dev/null || die "Install Ollama first from https://ollama.com/download"
command -v findmnt >/dev/null || die "findmnt missing"
mountpoint -q "$DATA" || die "$DATA must be a mounted filesystem; refusing to write on boot disk"
[[ "$(findmnt -rn -M "$DATA" -o FSTYPE)" == ext4 ]] || die "Expected mounted ext4 at $DATA"
[[ "$DATA" != "/" ]] || die "Refusing root filesystem"
id ollama >/dev/null || die "Ollama service user not found"
say "Storage"
findmnt -M "$DATA"
df -h "$DATA"
mkdir -p "$MODELS" "$WEBUI" "$DATA/models" "$DATA/datasets" "$DATA/projects" "$DATA/backups"

# Copy model files first, if needed. Never delete the originals.
ORIGINAL=/usr/share/ollama/.ollama/models
if [[ -d "$ORIGINAL" && "$ORIGINAL" != "$MODELS" ]]; then
  say "Copying any pre-existing model cache safely"
  apt-get install -y rsync
  rsync -a "$ORIGINAL/" "$MODELS/"
fi
chown -R ollama:ollama "$MODELS"
chmod 755 "$DATA" "$MODELS"

say "Configuring Ollama systemd drop-in"
mkdir -p "$(dirname "$DROPIN")"
if [[ -f "$DROPIN" ]]; then
  cp -a "$DROPIN" "$DROPIN.bak.$(date +%Y%m%d%H%M%S)"
fi
# Preserve non-model environment config by using drop-in only for this variable.
cat > "$DROPIN" <<EOF
[Service]
Environment="OLLAMA_MODELS=$MODELS"
EOF
systemctl daemon-reload
systemctl enable --now ollama
systemctl restart ollama
for i in {1..20}; do
  curl -fsS http://127.0.0.1:11434/api/version && break
  sleep 1
done
curl -fsS http://127.0.0.1:11434/api/version >/dev/null || die "Ollama API not responding"

say "Installing Docker (if missing)"
if ! command -v docker >/dev/null; then
  apt-get update
  apt-get install -y docker.io
fi
systemctl enable --now docker
docker info >/dev/null || die "Docker daemon not responding"

if docker container inspect open-webui >/dev/null 2>&1; then
  say "Existing Open WebUI container found; leaving untouched"
else
  say "Creating persistent Open WebUI container"
  if ss -lnt | grep -qE "[:.]$WEB_PORT[[:space:]]"; then
    die "Port $WEB_PORT already in use"
  fi
  SECRETFILE="$DATA/.open-webui-secret"
  if [[ ! -s "$SECRETFILE" ]]; then
    (umask 077; openssl rand -hex 32 > "$SECRETFILE")
  fi
  # Reference deployment. For reproducibility pin a release tag/digest in production.
  docker run -d --name open-webui --network host --restart unless-stopped \
    -e "PORT=$WEB_PORT" \
    -e "OLLAMA_BASE_URL=http://127.0.0.1:11434" \
    -e "WEBUI_SECRET_KEY=$(cat "$SECRETFILE")" \
    -v "$WEBUI:/app/backend/data" \
    ghcr.io/open-webui/open-webui:main
fi
say "Verification"
systemctl is-active ollama docker
systemctl show ollama -p Environment --no-pager
docker ps --filter name=open-webui
df -h "$DATA"
printf '\nBrowse to http://<your-LAN-IP>:%s (trusted LAN only)\n' "$WEB_PORT"
