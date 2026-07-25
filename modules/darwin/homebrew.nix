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
    casks = [
      "ghostty"
    ];
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "uninstall";
    };
  };
}
