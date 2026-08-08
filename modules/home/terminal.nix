{ isDarwin, lib, ... }:

{
  home.file.".local/bin/ghostty" = lib.mkIf isDarwin {
    executable = true;
    text = ''
      #!/bin/sh
      exec open -na Ghostty --args "$@"
    '';
  };

  xdg.configFile = {
    "ghostty/config".source = ../../config/ghostty/config;
    "ghostty/themes/catppuccin-latte".source = ../../config/ghostty/themes/catppuccin-latte;
    "ghostty/themes/catppuccin-mocha".source = ../../config/ghostty/themes/catppuccin-mocha;
    "lf/lfrc".source = ../../config/lf/lfrc;
  };
}
