# Step-by-step installation and verification

These instructions reconstruct the working HP Z440 setup. Install **Ubuntu Desktop 26.04.1 LTS** on the Samsung NVMe and keep the separate SATA data drive untouched until positively identified.

## 1. Prepare and inspect

```bash
sudo apt update
sudo apt full-upgrade -y
sudo apt install -y curl wget git build-essential htop nvme-cli smartmontools pciutils mesa-utils openssh-server lm-sensors
sudo systemctl enable --now ssh
lscpu
free -h
lsblk -o NAME,SIZE,MODEL,FSTYPE,MOUNTPOINTS
```

Confirm 22 physical cores/44 logical threads, 64 GB ECC memory, Samsung 950 PRO NVMe and 1 TB Western Digital HDD. Confirm a trusted remote SSH login. This does not verify ECC is enabled at the firmware/hardware level; inspect `sudo dmidecode -t memory` for reporting and motherboard settings.

## 2. NVIDIA GPU drivers

```bash
ubuntu-drivers devices
sudo apt install -y "linux-headers-$(uname -r)" nvidia-driver-580
sudo reboot
```

After reboot:

```bash
nvidia-smi
lsmod | grep nvidia
mokutil --sb-state
```

The observed working combination was driver **580.178.04**, Ubuntu Linux **7.0.0-38-generic**, Quadro M4000 and Secure Boot disabled. A GPU shown in `nvidia-smi` confirms the driver, not that every modern CUDA workload is supported.

## 3. Prepare data storage

See [storage.md](storage.md). The original 1 TB HDD was NTFS and was reformatted to ext4 **after the owner confirmed it contained nothing to keep**. The repository intentionally does not automate formatting. Mount the ext4 data partition by UUID at `/mnt/llm-data`; do not assume a particular `/dev/sdX` name.

```bash
findmnt /mnt/llm-data
df -h /mnt/llm-data
```

## 4. Ollama

Use the official Ollama Linux installation instructions: https://ollama.com/download/linux . Read third-party install scripts before executing them as root.

```bash
ollama --version
systemctl status ollama --no-pager
curl -fsS http://127.0.0.1:11434/api/version
```

If Ollama is working and the data drive is mounted, use the reference setup script for relocating the model cache and installing Docker/Open WebUI:

```bash
sudo bash scripts/setup-existing-ollama-webui.sh
```

It configures `OLLAMA_MODELS=/mnt/llm-data/ollama` using a systemd override, copies existing blobs without deleting their source, sets model directory ownership and creates a Docker container for Open WebUI. Validate configuration after execution:

```bash
systemctl show ollama -p Environment --no-pager
ollama list
sudo docker ps
curl -I http://127.0.0.1:3000
```

## 5. Models and profiles

```bash
ollama pull llama3.2:3b
ollama pull qwen3:8b
bash scripts/create-model-profiles.sh
ollama list
ollama run qwen3-z440:8b
ollama ps
```

A model is only in GPU memory when the **live** `ollama ps` shows its placement. The documented configuration showed `100% GPU` and 4K context for Qwen3 8B; it is not a promise for future environments.

Open `http://<Z440-LAN-IP>:3000` from a **trusted LAN** browser, create an admin account, select a model, and send a test prompt. Configure thinking mode explicitly in Open WebUI if needed.

## 6. Measure before tuning

```bash
bash scripts/check-z440.sh
python3 scripts/benchmark.py --model qwen3-z440:8b --repeats 3
```

Monitor a second terminal:

```bash
watch -n 2 'sensors | grep -E "Package id 0|Composite"; nvidia-smi'
```

Leave the CPU governor at the default `schedutil` until a repeated benchmark justifies changing it. CPU idle frequency ~1.2 GHz was not evidence of underperformance.

## 7. Security and recovery

Restrict Open WebUI to trusted LAN clients; do not forward TCP 3000 publicly. Ollama API should remain on localhost. Protect WebUI chat data, secret keys and logins. Back up Open WebUI's persistent data to a separate physical disk before upgrading the Docker image.

See [limitations and risks](limitations-and-risks.md) and [troubleshooting](troubleshooting.md).