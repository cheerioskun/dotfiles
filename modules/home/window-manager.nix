{ isDarwin, lib, ... }:

{
  xdg.configFile."aerospace/aerospace.toml" = lib.mkIf isDarwin {
    source = ../../config/aerospace/aerospace.toml;
  };
}
