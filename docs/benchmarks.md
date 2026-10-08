# Benchmarks and thermal results (observed on this Z440)

All speeds are generation tokens/second unless stated otherwise, reported from Ollama's `eval_count / eval_duration` metrics. These are short tests, not exhaustive comparisons.

## Llama 3.2 3B, 256 generated tokens

| Placement | Pass 1 | Pass 2 |
| --- | ---: | ---: |
| M4000 GPU | 21.44 | 21.37 |
| Xeon 8 CPU threads | 19.56 | 19.62 |
| Xeon 16 CPU threads | 22.37 | 22.24 |
| Xeon 22 CPU threads | **22.59** | **22.35** |
| Xeon 44 CPU threads | 21.96 | 21.59 |

One later GPU smoke test reported ~21.74 tok/s, virtually unchanged by a 4K-context tuned alias.

## Qwen3 8B, 256 generated tokens (thinking off)

| Placement | Generation | Prompt eval | Total |
| --- | ---: | ---: | ---: |
| M4000 100% GPU | **10.67 tok/s** | 38.62 tok/s | 28.21 s |
| Xeon, 22 CPU threads | 10.06 tok/s | **65.38 tok/s** | 32.85 s |

These Qwen values come from **one pass per mode**; repeat them before attributing small differences to hardware.

## GPU placement and VRAM

`ollama ps` showed `qwen3-z440:8b` with **100% GPU** and 4,096-token context. `nvidia-smi` showed 5,854 MiB / 8,192 MiB occupied while loaded (about 5,790 MiB by Ollama).

## Thermals

- Xeon CPU package at light/idle load: 36°C, with reported `high=83°C`, `crit=85°C`.
- CPU package in screenshot under activity: around 51°C (spot reading, not long-term soak).
- NVIDIA M4000 after a workload: 65°C at 59% fan, 13.24 W, idle GPU utilisation while model remained loaded.
- After unloading both Llama models, M4000 settled at **49°C**, 52% fan, ~12 W and 62 MiB in use.
- Qwen3 loaded but idle: **57°C**, 53% fan, ~12 W, 5,854 MiB in use.
- Samsung NVMe: ~31.9°C during initial check.

### Interpretation

For 3B, Xeon at 16–22 threads is competitive with or slightly faster than the M4000. For Qwen3 8B, M4000 narrowly won the first generation benchmark, leaving CPU resources for other work. Do not assume 44 hyperthreads is optimal. Model size, context, concurrency, prompt lengths, run-to-run variation and cooling all affect results.

## Reproduce

```bash
python3 scripts/benchmark.py --model qwen3-z440:8b --repeats 3
watch -n 2 'sensors | grep -E "Package id 0|Composite"; nvidia-smi'
ollama ps
```

Benchmark uses the Ollama HTTP API and requests no-thinking mode; support can vary by Ollama version. Do not run competing WebUI requests at the same time.
