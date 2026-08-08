{ ... }:
{
  # Home Manager is standalone on Ubuntu rather than embedded in a NixOS
  # configuration, so enable its integration for non-NixOS Linux hosts.
  targets.genericLinux.enable = true;
}
