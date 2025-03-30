{ ... }:

{
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    environmentVariables = {
      HCC_AMDGPU_TARGET = "gfx90c"; # used to be necessary, but doesn't seem to anymore
    };
    # rocmOverrideGfx = "90c";
  };
}
