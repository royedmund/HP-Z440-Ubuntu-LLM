# Qwen3 8B profiles

The setup retains `qwen3:8b` and creates `qwen3-z440:8b`, `qwen3-z440-fast:8b`, and `qwen3-z440-think:8b` using separate Modelfiles. Weight blobs are content-addressed and generally shared.

- **Normal**: 4K-context Qwen3 8B model for general conversation.
- **Fast**: concise default system instruction; intended for non-thinking tasks.
- **Think**: technical assistance style; intended for tasks needing more reasoning.

**Critical caveat:** The Modelfile `SYSTEM` text cannot reliably force Ollama's native thinking on/off state. Use Open WebUI's explicit Ollama thinking control, or in a direct API call pass a supported `think` boolean. In Qwen3, `/no_think` and `/think` can also affect behaviour, but test the result and do not depend on them for strict guarantees.

Run `bash scripts/create-model-profiles.sh`, refresh Open WebUI, and select the desired model. Profiles do not create a second 5.2 GB copy of identical quantised weights, but may create small additional metadata and configuration layers.

A 4,096 context preserves the observed full GPU placement of Qwen3 8B on the 8 GB M4000. A larger context may exceed available VRAM or reduce responsiveness. Check `ollama ps` after each change.
