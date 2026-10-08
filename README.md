# HP Z440 — Ubuntu 26.04 LTS Local LLM Workstation

A reproducible record of configuring an **HP Z440** as a desktop and local LLM server using **Ubuntu Desktop 26.04.1 LTS**, **NVIDIA Quadro M4000**, **Ollama**, **Docker**, and **Open WebUI**.

> Field notes from an actual October 2026 build. Hardware readings and benchmark numbers below are observed results, not guarantees for other machines. Scripts are reference implementations: read them, check device names, and back up data before running.

## Actual hardware

| Item | Configuration |
| --- | --- |
| Workstation | HP Z440 |
| CPU | Intel Xeon E5-2696 v4 (22 cores / 44 threads, AVX2) |
| RAM | 64 GB DDR4 ECC (Ubuntu reports ~60 GiB) |
| GPU | NVIDIA Quadro M4000, 8 GiB GDDR5, Maxwell (compute capability 5.2) |
| Boot | Samsung 950 PRO 256 GB NVMe |
| Data | Western Digital 1 TB SATA HDD (ext4, mounted at `/mnt/llm-data`) |
| OS | Ubuntu Desktop 26.04.1 LTS, Linux 7.0.0-38-generic |
| Driver observed | NVIDIA 580.178.04 (CUDA driver API reported 13.0) |
| Models | `llama3.2:3b`, `llama3.2-z440:3b`, `qwen3:8b`, `qwen3-z440:8b`, optional fast/think profiles |

**Important:** E5-2696 v4 is rated at 150 W, above the Z440's commonly documented 140 W CPU range. Confirm BIOS, cooling and power limits; this is an observed working configuration, not a blanket hardware compatibility guarantee.

## What worked

- Ubuntu boots from NVMe; SSH works; GNOME desktop uses the Quadro M4000.
- Ubuntu recommended the proprietary `nvidia-driver-580`. `nvidia-smi` and NVIDIA kernel modules worked with Secure Boot disabled.
- The existing NTFS data partition was replaced with ext4 **only after confirming its contents were disposable**; formatted separately from the NVMe boot disk.
- Ollama models were redirected to `/mnt/llm-data/ollama` via a systemd drop-in.
- Open WebUI runs in Docker on port 3000, with persisted application data on the HDD.
- Both Llama 3.2 3B and Qwen3 8B were confirmed by `ollama ps` as **100% GPU**, despite the older Maxwell architecture.
- Qwen3 8B occupied roughly 5.8 GiB GPU memory with 4K context.

## Quick start

1. Install Ubuntu Desktop 26.04.1 LTS to the NVMe. Update and enable SSH. Verify `lsblk`, `lscpu` and `nvidia-smi`.
2. **Do not run formatting commands based only on example device names.** Inspect `lsblk -f` and `findmnt`; see [storage](docs/storage.md).
3. Install Ollama from its official installation instructions; verify `systemctl status ollama`.
4. Run the supplied setup script after reviewing it:
   ```bash
   sudo bash scripts/setup-existing-ollama-webui.sh
   ```
   This script **requires an already formatted, mounted ext4 HDD** at `/mnt/llm-data` and a working Ollama installation. It never formats partitions.
5. Add the models and optional profiles:
   ```bash
   bash scripts/create-model-profiles.sh
   ```
6. Visit `http://<Z440-LAN-IP>:3000` on a trusted home network and create your admin account. **Never forward port 3000 to the public internet.**

## Documentation

- [Installation and service architecture](docs/install.md)
- [Data storage and safe mounting](docs/storage.md)
- [Benchmarks, thermal data and tuning notes](docs/benchmarks.md)
- [Troubleshooting and recovery](docs/troubleshooting.md)
- [Model profile caveats](docs/profiles.md)

## Repository layout

```text
scripts/
  setup-existing-ollama-webui.sh   # Checks mounted disk, configures Ollama, sets up Docker WebUI
  create-model-profiles.sh          # Qwen3 8B, and fast/think aliases
  benchmark.py                      # Repeatable Ollama API GPU/CPU comparisons
docs/
  install.md
  storage.md
  benchmarks.md
  profiles.md
  troubleshooting.md
```

## Key safety notes

- Formatting a block device **destroys data**. This repo intentionally provides no automatic formatter.
- Keep Ollama's API bound to localhost unless you deliberately implement authentication and network controls.
- The WebUI script uses Docker host networking for a direct localhost Ollama connection: **restrict HTTP port 3000 to a trusted LAN** (use VPN/HTTPS for remote access).
- CUDA 13.0 shown by `nvidia-smi` is *driver API capability*, not proof that the CUDA toolkit is installed.
- `/think` and `/no_think` system-message instructions are not a guaranteed replacement for the Ollama/Open WebUI explicit thinking toggle.

## Results snapshot

| Model | Device | Generation |
| --- | --- | ---: |
| Llama 3.2 3B | M4000 GPU | 21.44 tok/s |
| Llama 3.2 3B | Xeon, 22 threads CPU | 22.59 tok/s |
| Qwen3 8B (thinking disabled) | M4000 GPU | 10.67 tok/s |
| Qwen3 8B (thinking disabled) | Xeon, 22 threads CPU | 10.06 tok/s |

Single-pass illustrative figures; repeat before making performance claims. The 3B CPU and GPU results were also repeated in the original session (see benchmark notes).

## License

MIT (see `LICENSE`). Documentation and scripts are supplied without warranty. Model licenses and terms are controlled by their respective model authors.

## Attribution

Documented from a hands-on Ubuntu / Ollama / Open WebUI installation on an HP Z440, October 2026. Repository maintained by [royedmund](https://github.com/royedmund).
