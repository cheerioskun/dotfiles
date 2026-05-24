{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = config.dotfiles.userName;
in
{
  networking.hostName = "hemant-live";

  image.fileName = lib.mkForce "hemant-nix-hyprland-${pkgs.stdenv.hostPlatform.system}.iso";

  isoImage = {
    volumeID = lib.mkForce "HEMANT_NIX";
    squashfsCompression = "zstd -Xcompression-level 6";
  };

  # Keep the live image friendly in a VM: password is `nixos`, sudo is passwordless.
  users.users.${user}.initialPassword = lib.mkForce "nixos";
  services.getty.autologinUser = lib.mkDefault user;

  boot = {
    kernelParams = [ "copytoram" ];
    supportedFilesystems = [
      "btrfs"
      "ext4"
      "vfat"
      "ntfs"
    ];
  };

  environment.systemPackages = with pkgs; [
    calamares-nixos
    gparted
    parted
    rsync
  ];

  # The ISO should be disposable and easy to rebuild; avoid background GC surprises there.
  nix.gc.automatic = lib.mkForce false;
}
