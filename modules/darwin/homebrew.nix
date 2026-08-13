{ username, ... }:
{
  # nix-homebrew owns the Homebrew installation; nix-darwin owns its contents.
  nix-homebrew = {
    enable = true;
    user = username;
    autoMigrate = true;
    enableRosetta = false;
    mutableTaps = true;
  };

  homebrew = {
    enable = true;
    taps = [
      "magicmark/tap"
      "nikitabobko/tap"
    ];
    brews = [
      "gcc"
      "iproute2mac"
      "magicmark/tap/spacelist"
    ];
    casks = [
      "nikitabobko/tap/aerospace"
      "ghostty"
      "sublime-text"
    ];
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "uninstall";
    };
  };
}
