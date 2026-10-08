#!/usr/bin/env bash
# Read-only diagnostic report; no changes to OS or services.
set -u
echo "=== OS ==="
cat /etc/os-release | grep -E 'PRETTY_NAME|VERSION_ID'
uname -r
echo "=== CPU ==="
lscpu | grep -E 'Model name|CPU\(s\):|Core\(s\) per socket|Thread\(s\) per core'
echo "=== RAM ==="
free -h
echo "=== STORAGE ==="
lsblk -o NAME,SIZE,MODEL,FSTYPE,MOUNTPOINTS
findmnt /mnt/llm-data || true
df -h / /mnt/llm-data 2>/dev/null || true
echo "=== NVIDIA ==="
nvidia-smi --query-gpu=name,driver_version,temperature.gpu,fan.speed,power.draw,memory.used,memory.total --format=csv 2>/dev/null || true
echo "=== TEMPERATURES ==="
sensors 2>/dev/null | grep -E 'Package id 0:|Composite:' || true
echo "=== OLLAMA ==="
systemctl is-active ollama || true
systemctl show ollama -p Environment --no-pager || true
ollama list || true
ollama ps || true
echo "=== WEBUI ==="
systemctl is-active docker || true
sudo docker ps --filter name=open-webui --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true
curl -Is --max-time 3 http://127.0.0.1:3000 | head -n 1 || true
echo "=== NETWORK LISTENERS ==="
ss -lnt | grep -E '(:22|:3000|:11434)' || true
echo "=== END ==="
