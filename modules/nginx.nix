{ config, lib, ... }:

{
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  services.nginx = {
    enable = true;

    # enable recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
  };
  
  users.users.nginx.extraGroups = [ "acme" ];
}