{ ... }:
{
  imports = [ ../../modules/darwin ];

  networking = {
    computerName = "macbook";
    hostName = "macbook";
    localHostName = "macbook";
  };
}
