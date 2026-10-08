#!/usr/bin/env bash
# Create existing-model aliases; these share Qwen3 weight blobs.
set -Eeuo pipefail
command -v ollama >/dev/null || { echo "Ollama missing" >&2; exit 1; }
BASE="${QWEN_BASE:-qwen3:8b}"
DIR="${HOME}/z440-qwen3"
mkdir -p "$DIR"
echo "Pulling $BASE (reuses existing model if present)..."
ollama pull "$BASE"

cat > "$DIR/Modelfile.base" <<EOF
FROM $BASE
PARAMETER num_ctx 4096
PARAMETER temperature 0.6
EOF
ollama create qwen3-z440:8b -f "$DIR/Modelfile.base"

cat > "$DIR/Modelfile.fast" <<EOF
FROM $BASE
PARAMETER num_ctx 4096
PARAMETER temperature 0.6
SYSTEM """You are a concise, accurate assistant. Prefer non-thinking responses. For Qwen3, follow /no_think when supported. Do not reveal private reasoning."""
EOF
ollama create qwen3-z440-fast:8b -f "$DIR/Modelfile.fast"

cat > "$DIR/Modelfile.think" <<EOF
FROM $BASE
PARAMETER num_ctx 4096
PARAMETER temperature 0.6
SYSTEM """You are a careful technical assistant. Use the model's reasoning capability when appropriate, then present a clear final answer. For Qwen3, follow /think when supported."""
EOF
ollama create qwen3-z440-think:8b -f "$DIR/Modelfile.think"

echo
echo "Profiles created:"
ollama list | grep -E 'qwen3'
echo
echo "NOTE: These SYSTEM instructions alone do not guarantee mode selection."
echo "In Open WebUI Chat Controls set Ollama think Off for FAST and On for THINK."
echo "Weights are shared; model aliases generally require only small extra manifests."
