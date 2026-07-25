{ ... }:

{
  # The executable is installed by tool sync. Keep credentials, sessions, and
  # provider state out of Home Manager.
  home.file = {
    ".pi/agent/settings.json".source = ../../config/pi/settings.json;
    ".pi/agent/extensions" = {
      source = ../../config/pi/extensions;
      recursive = true;
    };
  };
}
