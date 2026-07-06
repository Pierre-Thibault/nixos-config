# RTX 5060 Ti used for local AI/ML compute only.
# No monitor is attached to it: the AMD iGPU stays the display GPU
# (see radeonsi config in configuration.nix), so no PRIME/output setup is needed here.
{ config, pkgs, ... }:

{
  boot.blacklistedKernelModules = [ "nouveau" ];

  nixpkgs.config.allowUnfree = true;

  # Required to actually activate hardware.nvidia (kernel module, nvidia-persistenced, etc.)
  # even though nothing is displayed through it. amdgpu stays first so Xorg/Xwayland
  # keeps defaulting to the iGPU if it ever starts.
  services.xserver.videoDrivers = [
    "amdgpu"
    "nvidia"
  ];

  hardware.nvidia = {
    # Blackwell (RTX 50 series) only works with the open kernel modules;
    # the proprietary driver doesn't support this generation at all.
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    nvidiaPersistenced = true;
  };

  environment.systemPackages = with pkgs; [
    cudatoolkit # nvcc + headers, needed if you build CUDA kernels from source (flash-attn, triton, ...)
    nvtopPackages.full # GPU usage monitor
  ];

  # cudatoolkit only ships a stub libcuda.so for linking; without this,
  # CUDA binaries fail at runtime with "CUDA driver version is insufficient".
  environment.sessionVariables.LD_LIBRARY_PATH = [ "/run/opengl-driver/lib" ];
}
