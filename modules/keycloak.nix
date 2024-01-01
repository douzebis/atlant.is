# https://stackoverflow.com/questions/25522360/ngrok-configure-multiple-port-in-same-domain
# https://ngrok.com/docs/ngrok-agent/config/
# https://dashboard.ngrok.com/get-started/your-authtoken

{ config, ... }:

{

  # sudo sponge /etc/nixos/secrets/keycloak.yaml <<EOF 
  # keycloak:
  #   db_password: $(cat /dev/urandom | LC_ALL=C tr -dc 'a-z' | head -c 16)
  # EOF
  # sudo sops --encrypt -i secrets/keycloak.yaml
  sops.secrets."keycloak/db_password" = {
    sopsFile = ../secrets/keycloak.yaml;
  };

  services.keycloak = {
    enable = true;
    settings = rec {
      http-host = "127.0.0.1";
      http-port = 3001;
      http-relative-path = "/";
      http-enabled = false;
      proxy = "edge";
      hostname-url = with { ng = config.custom.ngrok; };
        "https://keycloak.${ng.prefix}${ng.host}:${ng.port}";
      hostname-admin-url = hostname-url;
      hostname-strict-backchannel = true;
    };

    initialAdminPassword = "fred";  # change on first login

    database = {
      type = "postgresql";
      createLocally = true;
      username = "keycloak";
      passwordFile = config.sops.secrets."keycloak/db_password".path;
    };
  };

  security.acme.certs."keycloak" = rec {
      domain = with { ng = config.custom.ngrok; };
        "keycloak.${ng.prefix}${ng.host}";
      dnsProvider = "ovh";
      dnsPropagationCheck = true;
      credentialsFile = config.sops.secrets."ovh/credentials".path;
    };

  services.nginx.virtualHosts = {
    "keycloak.${config.custom.ngrok.prefix}${config.custom.ngrok.host}" = {
      useACMEHost = "keycloak";
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:3001";
    };
  };
}