{ config, ... }:

{
  # sudo sponge /etc/nixos/secrets/woodpecker.yaml <<EOF 
  # woodpecker:
  #   agent_secret: |
  #     WOODPECKER_AGENT_SECRET = $(cat /dev/urandom | LC_ALL=C tr -dc 'a-z' | head -c 16)
  # EOF
  # sudo sops --encrypt -i secrets/woodpecker.yaml
  sops.secrets."woodpecker/env" = {
    sopsFile = ../secrets/woodpecker.yaml;
    owner = config.services.nginx.user;
  };

  services.woodpecker-server = {
    enable = true;
    environment = {
      # Enable at first launch
      WOODPECKER_OPEN = "true";
      WOODPECKER_SERVER_ADDR = ":3003";
      WOODPECKER_HOST = with { ng = config.custom.ngrok; };
        "https://woodpecker.${ng.prefix}${ng.host}:${ng.port}";
      WOODPECKER_GITEA = "true";
      WOODPECKER_GITEA_CLIENT = "4e01bc36-5e5c-4200-ba69-20cfe4cc011c";
      WOODPECKER_GITEA_SECRET = "gto_xs4pnmimfhgof6zkfhmvbx3v7omuk2exep6smke5dssnrctcodkq";
      WOODPECKER_GITEA_URL = with { ng = config.custom.ngrok; };
        "https://gitea.${ng.prefix}${ng.host}:${ng.port}";
      WOODPECKER_ADMIN = "fred";
      # WOODPECKER_AGENT_SECRET is defined in environmentFile
    };
    environmentFile = [ config.sops.secrets."woodpecker/env".path ];
  };

  # This sets up a woodpecker agent
  services.woodpecker-agents.agents."docker" = {
    enable = true;
    # We need this to talk to the podman socket
    extraGroups = [
      "docker"
    #  "podman"
    ];
    environment = {
      WOODPECKER_SERVER = "localhost:9000";
      # WOODPECKER_AGENT_SECRET is defined in environmentFile
      WOODPECKER_MAX_WORKFLOWS = "4";
      #DOCKER_HOST = "unix:///run/podman/podman.sock";
      DOCKER_HOST = "unix:///var/run/docker.sock";
      WOODPECKER_BACKEND = "docker";
    };
    environmentFile = [ config.sops.secrets."woodpecker/env".path ];
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