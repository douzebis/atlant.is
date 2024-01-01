{ config, ... }:

{
security.acme.certs."www" = rec {
      domain = with { ng = config.custom.ngrok; };
        "www.${ng.prefix}${ng.host}";
      dnsProvider = "ovh";
      dnsPropagationCheck = true;
      credentialsFile = config.sops.secrets."ovh/credentials".path;
    };

  services.nginx.virtualHosts = {
    "www.${config.custom.ngrok.prefix}${config.custom.ngrok.host}" = {
      useACMEHost = "www";
      forceSSL = true;
      root = "/var/www/docusaurus/";
      locations."/".extraConfig = ''
        absolute_redirect off;
      '';
    };
  };
}