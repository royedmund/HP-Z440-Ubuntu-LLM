# Design decisions and hardware-specific rationale

## What this project aims to do
Run a local, largely self-contained chatbot on an existing HP Z440 while retaining Ubuntu Desktop, remote administration, and a browser-based UI for trusted home devices. Priorities: reuse hardware, avoid unnecessary spending, preserve existing Llama models, and favour reproducible incremental changes over risky system tuning.

## Why these choices?

| Choice | Reason | Trade-off |
|---|---|---|
| Ubuntu Desktop 26.04.1 LTS | Familiar Linux desktop, current packaged system drivers, long-lived LTS distribution | LTS still requires updates; newer kernels may expose legacy GPU driver regressions |
| Xeon E5-2696 v4 | Existing 22 physical cores, AVX2, 64 GB ECC system RAM support | Broadwell memory bandwidth, clock speed and energy efficiency are well behind modern CPUs |
| NVIDIA Quadro M4000 | Existing GPU with 8 GiB VRAM; was confirmed working with NVIDIA 580.178.04 | Maxwell CC 5.2 is old; future CUDA/Ollama releases may drop support, no modern tensor cores |
| Ollama | Simple systemd-managed service, model pulls, native API, GPU/CPU offload, Modelfiles | Runner support changes across versions; model profiles and thinking behaviour require validation |
| Open WebUI in Docker | Browser access from other trusted machines, data persistence | Another daemon, updates, authentication and network exposure to maintain |
| ext4 HDD for data | Keeps 256 GB NVMe clear; high model capacity | Slower cold model loads than NVMe; HDD is not a backup |
| 4,096-token context | Qwen3 8B fits entirely on M4000 at tested quantisation | Short for long documents and coding sessions |
| GPU as usual default | Qwen3 8B 10.67 tok/s GPU vs 10.06 tok/s CPU in initial test; frees Xeon for desktop and other tasks | Difference is small and only one Qwen benchmark pass; GPU loads still use power and may limit context |
| Fast/think aliases | Convenient model selection without duplicating core weight blobs | A SYSTEM instruction alone **does not reliably control** native Ollama thinking state; set explicit think mode in UI/API |

## Why Llama 3.2 3B first?
At roughly 2 GB downloaded, this is a cheap compatibility and performance smoke test, fits comfortably in the M4000's 8 GiB, and exposed the CPU/GPU speed difference. It remains useful for quick drafts when low latency matters. It is not as capable as larger models on complex tasks.

## Why Qwen3 8B next?
The quantised Ollama build downloaded approximately 5.2 GB. In the observed 4K setup it loaded into **100% GPU** at around 5.8 GiB VRAM, leaving space for desktop overhead. Qwen3 8B offers improved capacity for general discussion, coding and reasoning compared with 3B, with generation speed about half that of Llama 3.2 3B on this hardware. We did **not** establish that larger models are always better, or that 8B will fit at all contexts/quantisations.

## Why not force 44 Xeon threads?
In a 256-token Llama 3.2 3B test, 22 threads delivered 22.59 tok/s vs 21.96 tok/s with 44; a repeat yielded 22.35 vs 21.59. Hyper-threading and extra threads often face memory-bandwidth contention. Performance varies with model, prompt length and batch size.

## Why not tune CPU governor or overclock?
Idle CPU clock near 1.2 GHz under `schedutil` was expected; the system showed usable inference without forcing performance mode. The CPU has a 150 W TDP (above the Z440's commonly specified 140 W CPU range), so start with conservative software-level tuning and monitor temperatures and power under sustained load.

## What to check before changing hardware
Measure first-token latency, generation rate, prompt processing, model loading, GPU VRAM, power and temperature with your actual workloads. A GPU upgrade should weigh VRAM, Linux driver longevity, physical clearance, PCIe power connectors, PSU capacity, cooling, idle power and cost. Consumer GPU value often exceeds old data-centre accelerator value when software compatibility and active cooling are considered.
