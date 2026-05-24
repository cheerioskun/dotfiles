{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles;
in
{
  options.dotfiles = {
    userName = lib.mkOption {
      type = lib.types.str;
      default = "hemant";
      description = "Primary desktop user.";
    };
  };

  config = {
    system.stateVersion = "25.05";

    nix = {
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
        trusted-users = [
          "root"
          cfg.userName
        ];
        warn-dirty = false;
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
    };

    nixpkgs.config.allowUnfree = true;

    networking = {
      hostName = lib.mkDefault "hemant-nix";
      networkmanager.enable = true;
      firewall.enable = true;
    };

    time.timeZone = lib.mkDefault "Asia/Kolkata";
    i18n.defaultLocale = "en_US.UTF-8";

    console.keyMap = "us";

    users = {
      mutableUsers = true;
      users = {
        ${cfg.userName} = {
          isNormalUser = true;
          description = "Hemant";
          extraGroups = [
            "wheel"
            "networkmanager"
            "video"
            "audio"
            "input"
            "docker"
          ];
          shell = pkgs.zsh;
          initialPassword = "nixos";
        };
      };
    };

    security = {
      sudo.wheelNeedsPassword = false;
      polkit.enable = true;
      rtkit.enable = true;
    };

    programs = {
      zsh.enable = true;
      git.enable = true;
      neovim = {
        enable = true;
        defaultEditor = true;
      };
      nix-ld.enable = true;
    };

    boot.zfs.forceImportRoot = false;

    virtualisation = {
      docker.enable = true;
      spiceUSBRedirection.enable = true;
    };

    services = {
      dbus.enable = true;
      openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = true;
          PermitRootLogin = "no";
        };
      };
      qemuGuest.enable = lib.mkDefault true;
      spice-vdagentd.enable = lib.mkDefault true;
      resolved.enable = true;
      upower.enable = true;
      printing.enable = false;
    };

    hardware = {
      bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
      graphics.enable = true;
    };

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    environment.systemPackages = with pkgs; [
      # Shell/daily tooling mirrored from these dotfiles.
      bat
      bottom
      btop
      cacert
      chezmoi
      curl
      delta
      direnv
      fd
      fzf
      gh
      git
      go
      jq
      jujutsu
      less
      lf
      neovim
      nodejs_22
      ripgrep
      tmux
      unzip
      wget
      zoxide
      zsh

      # Nix authoring/admin.
      alejandra
      nil
      nixd
      nixfmt-rfc-style
      nixos-generators
      nvd

      # VM + rescue quality-of-life.
      pciutils
      usbutils
      inetutils
      lsof
      strace
    ];
  };
}
