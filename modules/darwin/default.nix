{
  homeDirectory,
  inputs,
  isDarwin,
  pkgs,
  username,
  ...
}:
{
  imports = [ ./homebrew.nix ];

  # Determinate owns the Nix daemon and /etc/nix/nix.conf. Its module disables
  # nix-darwin's competing Nix management while retaining darwin integration.
  determinateNix.enable = true;

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };

  system = {
    primaryUser = username;
    stateVersion = 6;
  };

  users.users.${username} = {
    home = homeDirectory;
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit
        homeDirectory
        inputs
        isDarwin
        username
        ;
    };
    users.${username}.imports = [
      inputs.determinate.homeManagerModules.default
      ../home
    ];
  };
}
