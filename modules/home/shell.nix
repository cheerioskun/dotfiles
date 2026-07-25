{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      path = "${config.home.homeDirectory}/.zsh_history";
      size = 50000;
      save = 50000;
      extended = true;
      expireDuplicatesFirst = true;
      findNoDups = true;
      ignoreAllDups = true;
      ignoreDups = true;
      ignoreSpace = true;
      saveNoDups = true;
      share = true;
    };

    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      cat = "bat --paging=never";
      cp = "cp -iv";
      mkdir = "mkdir -pv";
      mv = "mv -iv";
      preview = "bat --style=numbers --color=always";
      rm = "rm -iv";
      tat = "tmux attach-session";
      zshconfig = "\${EDITOR:-nvim} \"\${ZDOTDIR:-$HOME}/.zshrc\"";
    };

    initContent = lib.mkMerge [
      (lib.mkOrder 1000 (builtins.readFile ../../config/shell/init.zsh))
      (lib.mkOrder 1150 ''
        # Deliberately unmanaged, for machine-only experiments and emergency fixes.
        [[ ! -f "$HOME/.zshrc.local" ]] || source "$HOME/.zshrc.local"
      '')
    ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--border"
      "--height=40%"
      "--layout=reverse"
    ];
    fileWidget.options = [
      "--preview 'bat --style=numbers --color=always {}'"
    ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      command_timeout = 1000;
      format = "$directory$git_branch$git_status$fill$cmd_duration$jobs$direnv$mise$line_break$character";
      palette = "catppuccin_mocha";

      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
        vimcmd_symbol = "[❮](mauve)";
      };
      cmd_duration = {
        min_time = 2000;
        format = "[$duration]($style) ";
      };
      directory = {
        style = "bold blue";
        truncation_length = 4;
        truncate_to_repo = false;
      };
      fill.symbol = " ";
      git_branch = {
        symbol = " ";
        style = "mauve";
      };
      git_status.style = "yellow";
      jobs = {
        symbol = "✦";
        style = "peach";
      };
      line_break.disabled = false;
      mise = {
        disabled = false;
        symbol = "mise ";
        style = "overlay1";
      };

      palettes.catppuccin_mocha = {
        rosewater = "#f5e0dc";
        flamingo = "#f2cdcd";
        pink = "#f5c2e7";
        mauve = "#cba6f7";
        red = "#f38ba8";
        maroon = "#eba0ac";
        peach = "#fab387";
        yellow = "#f9e2af";
        green = "#a6e3a1";
        teal = "#94e2d5";
        sky = "#89dceb";
        sapphire = "#74c7ec";
        blue = "#89b4fa";
        lavender = "#b4befe";
        text = "#cdd6f4";
        subtext1 = "#bac2de";
        subtext0 = "#a6adc8";
        overlay2 = "#9399b2";
        overlay1 = "#7f849c";
        overlay0 = "#6c7086";
        surface2 = "#585b70";
        surface1 = "#45475a";
        surface0 = "#313244";
        base = "#1e1e2e";
        mantle = "#181825";
        crust = "#11111b";
      };
    };
  };

  home.packages = [ pkgs.zsh-completions ];
}
