{ ... }:

{
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    rocmOverrideGfx = "90c";
  };
}
