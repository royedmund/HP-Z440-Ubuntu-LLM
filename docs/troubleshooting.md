# Troubleshooting

## Shell reports `trap: ERR: bad trap`
Bash-specific scripts need `#!/usr/bin/env bash` as the **first bytes** of the file; a leading blank line causes the shell to ignore it. Fix that or run explicitly with `bash script.sh`. Check syntax using `bash -n script.sh`.

## `systemctl edit ollama` says new contents are empty
The text may have been entered outside the supported staging region, or the editor exited without saving. Inspect `systemctl cat ollama`; create a service drop-in at `/etc/systemd/system/ollama.service.d/override.conf`, reload systemd, restart, and inspect `systemctl show ollama -p Environment`.

## Model downloads fill root filesystem
Check `findmnt /mnt/llm-data`, `df -h`, `systemctl show ollama -p Environment`. An unmounted model directory may reside on the NVMe. Do not delete or format anything until the proper disk/mount path is identified.

## `nvidia-smi` fails
Check `ubuntu-drivers devices`, `lsmod | grep nvidia`, `mokutil --sb-state`, kernel headers, journal and `dkms status`. The observed working hardware used NVIDIA 580.178.04 on kernel 7.0.0-38-generic with Secure Boot disabled. Future drivers may drop Maxwell; don't blindly use the newest.

## Unexpected CPU rather than GPU inference
Check `ollama ps` while the model is actually running, `nvidia-smi` VRAM/usage, `journalctl -u ollama`, context window and other loaded models. The observed `qwen3-z440:8b` ran 100% GPU at 4K, but VRAM demands can rise with context and concurrent requests.

## Open WebUI not accessible
Check `docker ps`, `docker logs --tail 100 open-webui`, `curl -I http://localhost:3000`, LAN IP and firewall rules. Avoid router port forwarding to this HTTP endpoint. The sample uses Docker host networking so Ollama's localhost API is reachable.

## GPU seems hot while idle
Ollama may keep a model resident in VRAM after generating. Check `ollama ps`, stop a model with `ollama stop MODEL`, and compare `nvidia-smi`. Observed M4000 temperature declined 65°C to 49°C after unloading. High steady temperatures or excessive fan noise deserve cleaning and airflow checks.

## Benchmarks vary
Use the same model tag, quantisation, prompt, context and generated-token count. Disable competing requests; run several repetitions and compare medians. `eval_duration` and `eval_count` give generation speed; `total_duration` includes other factors. Review `docs/benchmarks.md`.
