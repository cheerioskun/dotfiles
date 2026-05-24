{
  config,
  lib,
  pkgs,
  ...
}:
let
  optionalPackage = name: (pkgs.${name} or null);
  present = lib.filter (pkg: pkg != null);
in
{
  config = {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          user = "greeter";
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --asterisks --cmd Hyprland";
        };
      };
    };

    environment.etc."greetd/environments".text = ''
      Hyprland
      zsh
    '';

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ];
      config.common.default = [
        "hyprland"
        "gtk"
      ];
    };

    services = {
      gvfs.enable = true;
      tumbler.enable = true;
      blueman.enable = true;
    };

    fonts = {
      fontDir.enable = true;
      packages = with pkgs; [
        inter
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
      ];
      fontconfig.defaultFonts = {
        sansSerif = [
          "Inter"
          "Noto Sans"
        ];
        monospace = [ "JetBrainsMono Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
    };

    environment.systemPackages = present (
      (with pkgs; [
        # Hyprland essentials.
        brightnessctl
        cliphist
        grim
        hyprcursor
        hypridle
        hyprland
        hyprlock
        hyprpaper
        hyprpicker
        hyprshot
        libnotify
        mako
        pamixer
        playerctl
        slurp
        swappy
        swww
        wayland-utils
        wl-clipboard
        wofi
        wlogout
        xdg-utils

        # A slim but useful desktop baseline.
        firefox
        kitty
        nautilus
        networkmanagerapplet
        pavucontrol
        pwvucontrol
        qt6.qtwayland
        vscode
        xfce.thunar
      ])
      ++ [
        (optionalPackage "quickshell")
      ]
    );
  };
}
