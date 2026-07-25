{
  config,
  homeDirectory,
  isDarwin,
  username,
  ...
}:

{
  imports = [
    ../../profiles/cli.nix
    ./editor.nix
    ./mise.nix
    ./pi.nix
    ./shell.nix
    ./terminal.nix
    ./tmux.nix
    ./vcs.nix
  ];

  home = {
    inherit homeDirectory username;
    stateVersion = "26.05";

    sessionPath = [
      "${homeDirectory}/.local/bin"
      "${homeDirectory}/go/bin"
    ];

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less";
      LESS = "-FRX";
    }
    // (
      if isDarwin then
        {
          HOMEBREW_NO_ANALYTICS = "1";
          HOMEBREW_NO_AUTO_UPDATE = "1";
          HOMEBREW_NO_ENV_HINTS = "1";
          HOMEBREW_NO_INSTALL_CLEANUP = "1";
        }
      else
        { }
    );
  };

  programs.home-manager.enable = true;

  xdg.enable = true;
}
