{ lib, pkgs, ... }:

{
  home.packages =
    (with pkgs; [
      bat
      cacert
      curl
      fd
      file
      jq
      less
      lf
      postgresql
      ripgrep
      rustup
      trash-cli
      unzip
      uv
      zsh
    ])
    ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.gcc ];
}
