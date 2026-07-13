# Local LLM inference on the RTX 5060 (see nvidia-ai.nix for the CUDA setup
# this depends on). Server listens on 127.0.0.1:11434 only, no firewall
# opening: local use / open-webui (ai-tools.nix) only.
{ pkgs, ... }:

{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    loadModels = [
      "qwen3:14b"
      "mistral-small3.2:24b"
    ];
    # Default 4k (auto-picked from VRAM) is too small for agentic tool-calling
    # clients (OpenCode, etc.) that send large tool schemas/file context.
    # Comfortable for qwen3:14b (~9.6GB weights, plenty of VRAM headroom left);
    # mistral-small3.2:24b (~15GB weights) has very little VRAM margin, so a
    # 16k context on that model may spill KV cache to CPU (slower) rather than
    # fail outright.
    environmentVariables.OLLAMA_CONTEXT_LENGTH = "16384";
  };

  # http://ollama.local:11434
  networking.hosts."127.0.0.1" = [ "ollama.local" ];
}
