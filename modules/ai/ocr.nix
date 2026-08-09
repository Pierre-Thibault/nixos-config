# EasyOCR (pip-installed, prebuilt CUDA wheels) needs libstdc++.so.6 and a
# few other libs absent from NixOS's default library search path. nixpkgs'
# own python3Packages.torch with cudaSupport has no matching binary in the
# CUDA cache for this GPU (RTX 5060 Ti / Blackwell) — building from source
# is a multi-hour job — so ocr-screenshot.py points LD_LIBRARY_PATH at this
# stable, Nix-managed path instead (kept in sync with nixpkgs on every
# rebuild, unlike a raw /nix/store/... path which can be garbage-collected).
#
# The venv itself (torch/easyocr, pip-installed) is NOT managed by Nix —
# bootstrap once with:
#   python3 -m venv ~/.local/share/ocr-screenshot/venv
#   ~/.local/share/ocr-screenshot/venv/bin/pip install --index-url https://download.pytorch.org/whl/cu132 torch torchvision
#   ~/.local/share/ocr-screenshot/venv/bin/pip install easyocr
{ pkgs, ... }:

let
  ocrLibs = pkgs.symlinkJoin {
    name = "ocr-screenshot-libs";
    paths = [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.glib
    ];
  };
in
{
  environment.etc."ocr-screenshot-libs".source = "${ocrLibs}/lib";
}
