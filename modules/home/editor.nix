{
  isDarwin,
  lib,
  pkgs,
  ...
}:

let
  sublimeUser = "Library/Application Support/Sublime Text/Packages/User";
  sublimeConfig = ../../config/sublime;
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  home.file = lib.mkIf isDarwin {
    "${sublimeUser}/CSES C++.sublime-build" = {
      source = "${sublimeConfig}/CSES C++.sublime-build";
      force = true;
    };
    "${sublimeUser}/CSES Layout.sublime-commands" = {
      source = "${sublimeConfig}/CSES Layout.sublime-commands";
      force = true;
    };
    "${sublimeUser}/CSES Rust.sublime-build" = {
      source = "${sublimeConfig}/CSES Rust.sublime-build";
      force = true;
    };
    "${sublimeUser}/Package Control.sublime-settings" = {
      source = "${sublimeConfig}/Package Control.sublime-settings";
      force = true;
    };
    "${sublimeUser}/cpp-cp-boiler.sublime-snippet" = {
      source = "${sublimeConfig}/cpp-cp-boiler.sublime-snippet";
      force = true;
    };
    "${sublimeUser}/rust-cses.sublime-snippet" = {
      source = "${sublimeConfig}/rust-cses.sublime-snippet";
      force = true;
    };
    "${sublimeUser}/setup_cses_layout.py" = {
      source = "${sublimeConfig}/setup_cses_layout.py";
      force = true;
    };

    "Library/Application Support/Sublime Text/Installed Packages/Package Control.sublime-package" = {
      source = pkgs.fetchurl {
        url = "https://packagecontrol.io/Package%20Control.sublime-package";
        hash = "sha256-gXk3FEw0yEyIzUO4UxiyZW+cP6wC+PcsvBg2Cywm0Tk=";
      };
      force = true;
    };
  };
}
