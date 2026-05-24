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
  config = {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";

      users.${user} =
        { pkgs, ... }:
        {
          home = {
            username = user;
            homeDirectory = "/home/${user}";
            stateVersion = "25.05";

            packages = with pkgs; [
              fastfetch
              lazydocker
              lazygit
            ];

            sessionVariables = {
              EDITOR = "nvim";
              VISUAL = "nvim";
              TERMINAL = "kitty";
            };
          };

          programs.home-manager.enable = true;

          programs.git = {
            enable = true;
            settings = {
              init.defaultBranch = "main";
              pull.rebase = true;
              push.autoSetupRemote = true;
            };
          };

          programs.delta = {
            enable = true;
            enableGitIntegration = true;
          };

          programs.direnv = {
            enable = true;
            nix-direnv.enable = true;
          };

          programs.zoxide = {
            enable = true;
            enableZshIntegration = true;
          };

          programs.fzf = {
            enable = true;
            enableZshIntegration = true;
          };

          programs.bat.enable = true;
          programs.btop.enable = true;
          programs.tmux = {
            enable = true;
            mouse = true;
            keyMode = "vi";
            terminal = "screen-256color";
          };

          programs.zsh = {
            enable = true;
            autosuggestion.enable = true;
            syntaxHighlighting.enable = true;
            enableCompletion = true;
            shellAliases = {
              cat = "bat --paging=never";
              g = "git";
              j = "jj";
              ll = "ls -lah";
              v = "nvim";
            };
            initContent = ''
              # Local escape hatch: keep secrets and machine-only tweaks out of Nix.
              [[ ! -f "$HOME/.zshrc.local" ]] || source "$HOME/.zshrc.local"
            '';
          };

          wayland.windowManager.hyprland = {
            enable = true;
            systemd.enable = true;
            configType = "hyprlang";
            settings = {
              "$mod" = "SUPER";

              monitor = [
                ",preferred,auto,1"
              ];

              exec-once = [
                "mako"
                "quickshell"
                "wl-paste --type text --watch cliphist store"
                "wl-paste --type image --watch cliphist store"
              ];

              input = {
                kb_layout = "us";
                follow_mouse = 1;
                touchpad = {
                  natural_scroll = true;
                  tap-to-click = true;
                };
                sensitivity = 0;
              };

              general = {
                gaps_in = 4;
                gaps_out = 8;
                border_size = 2;
                "col.active_border" = "rgba(8aadf4ff) rgba(c6a0f6ff) 45deg";
                "col.inactive_border" = "rgba(363a4fff)";
                layout = "dwindle";
              };

              decoration = {
                rounding = 10;
                blur = {
                  enabled = true;
                  size = 4;
                  passes = 2;
                };
                shadow = {
                  enabled = true;
                  range = 16;
                  render_power = 2;
                  color = "rgba(00000033)";
                };
              };

              animations = {
                enabled = true;
                bezier = [
                  "ease,0.25,0.1,0.25,1"
                  "pop,0.05,0.9,0.1,1.05"
                ];
                animation = [
                  "windows,1,4,pop"
                  "border,1,5,ease"
                  "fade,1,4,ease"
                  "workspaces,1,4,ease"
                ];
              };

              dwindle = {
                pseudotile = true;
                preserve_split = true;
              };

              misc = {
                disable_hyprland_logo = true;
                force_default_wallpaper = 0;
              };

              bind = [
                "$mod, RETURN, exec, kitty"
                "$mod, SPACE, exec, wofi --show drun"
                "$mod, B, exec, firefox"
                "$mod, E, exec, nautilus"
                "$mod, Q, killactive"
                "$mod SHIFT, Q, exit"
                "$mod, F, fullscreen"
                "$mod, V, togglefloating"
                "$mod, P, pseudo"
                "$mod, L, exec, hyprlock"
                "$mod, PRINT, exec, hyprshot -m region"
                ", PRINT, exec, hyprshot -m output"
                "$mod, C, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"
                "$mod, left, movefocus, l"
                "$mod, right, movefocus, r"
                "$mod, up, movefocus, u"
                "$mod, down, movefocus, d"
                "$mod SHIFT, left, movewindow, l"
                "$mod SHIFT, right, movewindow, r"
                "$mod SHIFT, up, movewindow, u"
                "$mod SHIFT, down, movewindow, d"
              ]
              ++ (builtins.concatLists (
                builtins.genList (
                  i:
                  let
                    ws = toString (i + 1);
                    key = if i == 9 then "0" else ws;
                  in
                  [
                    "$mod, ${key}, workspace, ${ws}"
                    "$mod SHIFT, ${key}, movetoworkspace, ${ws}"
                  ]
                ) 10
              ));

              bindm = [
                "$mod, mouse:272, movewindow"
                "$mod, mouse:273, resizewindow"
              ];

              bindel = [
                ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
                ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
                ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
                ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
                ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
              ];
            };
          };

          services.mako = {
            enable = true;
            settings = {
              background-color = "#181926";
              border-color = "#8aadf4";
              text-color = "#cad3f5";
              border-radius = 10;
              default-timeout = 5000;
            };
          };

          programs.kitty = {
            enable = true;
            font = {
              name = "JetBrainsMono Nerd Font";
              size = 12;
            };
            settings = {
              background_opacity = "0.92";
              confirm_os_window_close = 0;
            };
          };

          home.file.".config/quickshell/shell.qml".text = ''
            import QtQuick
            import Quickshell

            PanelWindow {
              anchors { top: true; left: true; right: true }
              implicitHeight: 32
              color: "#181926"

              property string now: Qt.formatDateTime(new Date(), "ddd dd MMM  HH:mm")

              Text {
                anchors.centerIn: parent
                color: "#cad3f5"
                font.family: "Inter"
                font.pixelSize: 13
                text: "hemant-nix  •  " + parent.now
              }

              Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: parent.now = Qt.formatDateTime(new Date(), "ddd dd MMM  HH:mm")
              }
            }
          '';
        };
    };
  };
}
