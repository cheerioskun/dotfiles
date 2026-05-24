{ lib, pkgs, ... }:
{
  networking.hostName = "hemant-vm";

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "virtio_pci"
      "virtio_blk"
      "virtio_scsi"
      "sd_mod"
      "sr_mod"
    ];
  };

  # Generic install target. Replace this with nixos-generate-config output on real hardware.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  swapDevices = [ ];

  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 4096;
      cores = 4;
      graphics = true;
    };
  };
}
