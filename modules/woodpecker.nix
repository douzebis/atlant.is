{ config, ... }:

{
  # sudo sponge /etc/nixos/secrets/woodpecker.yaml <<EOF 
  # woodpecker:
  #   agent_secret: |
  #     WOODPECKER_AGENT_SECRET = $(cat /dev/urandom | LC_ALL=C tr -dc 'a-z' | head -c 16)
  # EOF
  # sudo sops --encrypt -i secrets/woodpecker.yaml
  sops.secrets."woodpecker/environment" = {
    sopsFile = ../secrets/woodpecker.env;
    owner = config.services.woodpecker.user;
  };

  services.woodpecker-server = {
    enable = true;
    environment = {
      # Enable at first launch
      WOODPECKER_OPEN = "true";
      WOODPECKER_SERVER_ADDR = ":3007";
      WOODPECKER_HOST = "https://woodpecker.douzeb.is";
      WOODPECKER_GITEA = "true";
      WOODPECKER_GITEA_CLIENT = "287fcafa-d7ec-4bce-8ca3-b63415aa538f";
      WOODPECKER_GITEA_SECRET = "gto_xqmfiblsdypfpkkwksaeyte54mvt27qutenq42lwk33rjrkvr6uq";
      WOODPECKER_GITEA_URL = "https://gitea.douzeb.is";
      WOODPECKER_ADMIN = "fred";
      #WOODPECKER_AGENT_SECRET = builtins.readFile config.sops.secrets."woodpecker/agent_secret".path;
    };
    #environmentFile = config.sops.secrets."woodpecker/agent_secret".path;
    environmentFile = config.sops.secrets."woodpecker/environment".path;
  };

  # This sets up a woodpecker agent
  services.woodpecker-agents.agents."docker" = {
    enable = true;
    # We need this to talk to the podman socket
    extraGroups = [
      "docker"
      "podman"
    ];
    environment = {
      WOODPECKER_SERVER = "localhost:9000";
      #WOODPECKER_AGENT_SECRET = builtins.readFile config.sops.secrets."woodpecker/agent_secret".path;
      WOODPECKER_MAX_WORKFLOWS = "4";
      DOCKER_HOST = "unix:///run/podman/podman.sock";
      WOODPECKER_BACKEND = "docker";
    };
    environmentFile = config.sops.secrets."woodpecker/environment".path;
    #environmentFile = "/run/secrets/woodpecker/environment";
  };

  # Here we setup podman and enable dns
  virtualisation.podman = {
    enable = true;
    defaultNetwork.settings = {
      dns_enabled = true;
    };
  };

  # This is needed for podman to be able to talk over dns
  networking.firewall.interfaces."podman0" = {
    allowedUDPPorts = [ 53 ];
    allowedTCPPorts = [ 53 ];
  };

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