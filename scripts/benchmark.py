#!/usr/bin/env python3
"""Compare Ollama CPU and GPU configurations using Ollama API. Python stdlib only."""
import json
import statistics
import urllib.request
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--model", default="qwen3-z440:8b")
parser.add_argument("--repeats", type=int, default=3)
parser.add_argument("--tokens", type=int, default=256)
args = parser.parse_args()
if args.repeats < 1:
    parser.error("--repeats must be positive")

url = "http://127.0.0.1:11434/api/generate"
prompt = ("Explain GPU and CPU inference for local language models, including "
          "memory bandwidth, model quantisation, AVX2 and context length.")
tests = [("GPU", 99, 8), ("CPU 16 threads", 0, 16), ("CPU 22 threads", 0, 22),
         ("CPU 44 threads", 0, 44)]

def run(gpu, threads):
    request = {
        "model": args.model,
        "prompt": prompt + " /no_think",
        "think": False,
        "stream": False,
        "keep_alive": "0",
        "options": {
            "num_gpu": gpu, "num_thread": threads, "num_ctx": 4096,
            "num_predict": args.tokens, "temperature": 0, "seed": 42
        }
    }
    data = json.dumps(request).encode()
    req = urllib.request.Request(url, data=data,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=900) as response:
        result = json.load(response)
    count = result.get("eval_count", 0)
    duration = result.get("eval_duration", 0)
    prompt_count = result.get("prompt_eval_count", 0)
    prompt_duration = result.get("prompt_eval_duration", 0)
    if duration <= 0:
        raise RuntimeError(f"Missing generation timing: {result}")
    return (count / (duration / 1e9),
            (prompt_count / (prompt_duration / 1e9)) if prompt_duration else 0)

print(f"Model: {args.model}; repeats: {args.repeats}; generated token cap: {args.tokens}")
print("No other Ollama requests should be running. Run repeated tests under similar conditions.")
for label, gpu, threads in tests:
    speeds, prompts = [], []
    for _ in range(args.repeats):
        speed, prompt_speed = run(gpu, threads)
        speeds.append(speed)
        prompts.append(prompt_speed)
    print(f"{label:16} median generation: {statistics.median(speeds):6.2f} tok/s; "
          f"median prompt: {statistics.median(prompts):6.2f} tok/s")
print("Caution: GPU/CPU placement should be verified separately with 'ollama ps' during a run.")
