{ config, ... }:

{
security.acme.certs."woodpecker" = rec {
      domain = with { ng = config.custom.ngrok; };
        "woodpecker.${ng.prefix}${ng.host}";
      dnsProvider = "ovh";
      dnsPropagationCheck = true;
      credentialsFile = config.sops.secrets."ovh/credentials".path;
    };

  services.nginx.virtualHosts = {
    "woodpecker.${config.custom.ngrok.prefix}${config.custom.ngrok.host}" = {
      useACMEHost = "woodpecker";
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:3003";
    };
  };
}