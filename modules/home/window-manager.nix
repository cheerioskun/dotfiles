{ isDarwin, lib, ... }:

{
  xdg.configFile."aerospace/aerospace.toml" = lib.mkIf isDarwin {
    source = ../../config/aerospace/aerospace.toml;
    onChange = ''
      if /usr/bin/pgrep -x AeroSpace >/dev/null; then
        /opt/homebrew/bin/aerospace reload-config || true
      fi
    '';
  };
}
