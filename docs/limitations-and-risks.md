# Limitations, risks, and failure modes

These are important considerations for using an older workstation as a home LLM server.

## Hardware

- **Quadro M4000 is Maxwell (compute capability 5.2)**. The installed NVIDIA 580 driver worked on Ubuntu 26.04.1 with the user's Ollama build, but future NVIDIA/CUDA/Ollama releases may end compatibility. Keep a known-good driver and OS update recovery plan. A `nvidia-smi` CUDA version number is not proof a modern CUDA toolkit will run every workload.
- **8 GiB VRAM ceiling**. The observed Qwen3 8B quantisation occupied ~5.8 GiB at 4K context. Larger quantisations, contexts, parallel sessions and extra GPU desktop usage can exceed VRAM and cause partial CPU offload or load failures. 100% GPU is a measurement at one configuration, not a permanent property of the model.
- **Legacy CPU and TDP**. The E5-2696 v4's 22 cores are useful, but low memory bandwidth per core and older instructions constrain inference. Its 150 W TDP exceeds the HP Z440's commonly documented 140 W CPU envelope. Monitor clock throttling and cooling during a sustained workload rather than trusting one 36–51°C snapshot.
- **Electricity and noise**. Older workstations can be comparatively power-hungry, especially at idle. Fan ramping under model inference may make desktop/office use less pleasant. Measure whole-system power rather than extrapolating from GPU readings.
- **ECC benefits are limited**. ECC memory can help detect/correct some memory errors, but it does not guarantee correct AI answers, prevent software crashes or protect against disk failure.

## Software and model behaviour

- **Model quality**. Qwen3 8B can hallucinate, misunderstand niche technical details, produce outdated factual claims and give unsafe operational advice. Validate important output against primary sources and never rely on an unverified LLM answer for critical decisions.
- **Thinking mode**. The Qwen3 family supports thinking and non-thinking behaviour; special prompts such as `/think` and `/no_think` are less robust than a supported explicit Ollama API/UI switch. Separate aliases help organisation but are not a technical security or mode enforcement boundary.
- **Benchmarks are narrow**. Generation rate in tokens/s is not the same as wall-clock response time. Longer prompts, larger context, model load time, thermal soak and concurrent users produce different outcomes. Most published numbers here are short, single-run tests.
- **Upgrade drift**. An Ubuntu update, NVIDIA driver change, Ollama release, Open WebUI image or model quantisation update may alter behaviour. Record version numbers before making changes; keep rollback plans and database backups.
- **GPU/CPU detection**. If acceleration silently stops, verify with `ollama ps`, `nvidia-smi`, service logs and a controlled benchmark. Do not assume VRAM usage alone means the *entire* model is GPU-resident.

## Storage and reliability

- **HDD vs NVMe**. The 1 TB SATA HDD is economical for model storage but makes cold model loading, downloads, datasets and WebUI database I/O slower than SSD. Once weights are loaded, token generation typically depends more on CPU/GPU and memory.
- **One drive is not backup**. An ext4 HDD can fail, corrupt or fill up. Back up Open WebUI account data, chats, prompts, configuration and customised Modelfiles to *another* physical device. Ollama model weights can usually be downloaded again.
- **Mount failure hazard**. A missing `/mnt/llm-data` mount can redirect writes onto the NVMe, filling it. Verify `findmnt` before downloads and consider a systemd `RequiresMountsFor=/mnt/llm-data` override for Ollama.
- **Reformatting risk**. Device names may change across boots or hardware changes. Never run `mkfs.ext4 /dev/sda2` based on this machine's historical layout without validating the target by serial/UUID.

## Security and privacy

- **Local isn't automatically private**. WebUI and SSH are network services; saved prompts, chat histories and attachments reside on the server. Keep trusted users only, patch regularly, use strong logins, restrict firewall ports and avoid exposing Ollama API publicly.
- **The example Docker uses `--network host`**. This is simple for reaching localhost Ollama but exposes Open WebUI's listening port on accessible host interfaces. Restrict TCP/3000 at the firewall and router. Prefer a VPN or HTTPS reverse proxy if remote access is needed.
- **Open WebUI's `:main` image is mutable**. For reproducibility and safer updates, pin a tested version/digest rather than adopting changes unintentionally. Back up its persistent data before upgrades.
- **Secrets**. Do not commit passwords, SSH private keys, API tokens, database contents, user documents or the Open WebUI secret file to GitHub. Public repository documentation should use placeholders for IP addresses and user accounts.
- **Supply chain**. Review downloaded installation scripts, keep Docker images current but controlled, and validate sources before executing scripts as root.

## Functional limits

This machine is well suited to a single-user home AI assistant and experimentation; it is **not** a replacement for enterprise-grade multi-user inference hosting. Concurrent requests, large documents, advanced long-context reasoning, fine-tuning and large multimodal models will likely require more modern hardware. A future GPU upgrade should be driven by measured needs rather than headline VRAM alone.

## Operational recovery checklist

1. Check disk mounts and free space: `findmnt /mnt/llm-data && df -h`.
2. Check services: `systemctl status ollama docker`, `docker ps`.
3. Check NVIDIA: `nvidia-smi`, `lsmod | grep nvidia`.
4. Check models: `ollama list`, `ollama ps`, `ollama show qwen3-z440:8b`.
5. Check logs: `journalctl -u ollama -n 100 --no-pager`, `docker logs --tail 100 open-webui`.
6. If a service fails after an update, **diagnose before blindly upgrading/reinstalling**; preserve model data and Open WebUI database.
