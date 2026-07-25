{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
      init.defaultBranch = "main";
      fetch.prune = true;
      pull.rebase = true;
      push.autoSetupRemote = true;
      rerere.enabled = true;
      merge.conflictStyle = "zdiff3";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      features = "decorations";
      line-numbers = true;
      navigate = true;
      side-by-side = false;
    };
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
    };
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      ui = {
        default-command = "log";
        diff-editor = ":builtin";
        pager = "less -FRX";
      };
    };
  };

  home.file.".psqlrc".text = ''
    \pset pager always
    \pset null '∅'
    \timing on
    \x auto
  '';
}
