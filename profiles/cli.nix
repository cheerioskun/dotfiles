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
      libpq
      ripgrep
      trash-cli
      unzip
      uv
      zsh
    ])
    ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.gcc ];
}
