{ config, lib, ... }:

{

  custom.ngrok.prefix = "";
  custom.ngrok.host = "ruget.org";
  custom.ngrok.port = "11217";

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
}