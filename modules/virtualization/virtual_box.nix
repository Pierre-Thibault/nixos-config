{
  userdata,
  ...
}:
{
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "${userdata.username}" ];
  nixpkgs.config.allowUnfree = true;
  # Extension Pack disabled 2026-11-24: it is unfree, so not on
  # cache.nixos.org, and forced a long local VirtualBox rebuild on every
  # nixpkgs bump. Only needed for USB 2/3 passthrough, webcam passthrough,
  # VRDP, disk encryption, PXE. Clipboard sharing does not need it.
  virtualisation.virtualbox.host.enableExtensionPack = false;
  # guest.* removed 2026-07-23: this machine is the VirtualBox *host*,
  # never a guest — those options only produced boot noise every time
  # (vboxguest/vboxsf module load failures, vboxnet0-start errors,
  # dev-vboxguest.device timeout) with no chance of ever succeeding.
  # Host↔guest clipboard sharing for VMs run from here is configured per-VM
  # (VBoxManage --clipboard-mode / VirtualBox's own Devices menu) plus
  # Guest Additions inside each guest OS — unrelated to this file.
}
