{
  isDarwin,
  lib,
  pkgs,
  ...
}:

{
  home.packages = lib.optionals (!isDarwin) [ pkgs.wl-clipboard ];

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    escapeTime = 0;
    historyLimit = 50000;
    keyMode = "vi";
    mouse = true;
    prefix = "C-a";
    sensibleOnTop = true;
    terminal = "tmux-256color";

    plugins = with pkgs.tmuxPlugins; [
      yank
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor "mocha"
          set -g @catppuccin_window_status_style "rounded"
          set -g @catppuccin_window_text " #W"
          set -g @catppuccin_window_current_text " #W"
          set -g @catppuccin_directory_text "#{pane_current_path}"
        '';
      }
    ];

    extraConfig = ''
      set -ag terminal-overrides ",xterm-256color:RGB"
      set -g pane-base-index 1
      set -g renumber-windows on

      bind C-a send-prefix

      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi y send -X copy-selection-and-cancel

      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      set -g status-position bottom
      set -g status-interval 5
      set -g status-left-length 80
      set -g status-right-length 120
      set -g status-left ""
      set -g status-right "#{E:@catppuccin_status_directory}"
      set -ag status-right "#{E:@catppuccin_status_session}"
      set -ag status-right "#{E:@catppuccin_status_host}"

      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded"
    '';
  };
}
