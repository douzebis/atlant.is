{ config, ... }:

{
  # sudo sponge /etc/nixos/secrets/postgres.yaml <<EOF 
  # postgres:
  #   gitea_dbpass: $(cat /dev/urandom | LC_ALL=C tr -dc 'a-z' | head -c 16)
  # EOF
  # sudo sops --encrypt -i secrets/postgres.yaml
  sops.secrets."postgres/gitea_dbpass" = {
    sopsFile = ../secrets/postgres.yaml;
    owner = config.services.gitea.user;
  };

  # sudo sponge /etc/nixos/secrets/captain.yaml <<EOF 
  # captain:
  #   email_passwd: xxxxxxxx
  # EOF
  # sudo sops --encrypt -i secrets/captain.yaml
  sops.secrets."captain/email_passwd" = {
    sopsFile = ../secrets/captain.yaml;
    owner = config.services.gitea.user;
  };

  services.gitea = {
    enable = true;
    appName = "gitea"; # Give the site a name
    database = {
      type = "postgres";
      passwordFile = config.sops.secrets."postgres/gitea_dbpass".path;
    };
    settings.log = {
      MODE = "file";
      LEVEL = "Debug";
      ROOT_PATH = "/var/lib/gitea/log"; # /var/log/gitea causes an error
    };
    settings.server = {
      DOMAIN = with { ng = config.custom.ngrok; };
        "gitea.${ng.prefix}${ng.host}:${ng.port}";
      ROOT_URL = with { ng = config.custom.ngrok; };
        "https://gitea.${ng.prefix}${ng.host}:${ng.port}";
      HTTP_ADDR = "127.0.0.1";
      HTTP_PORT = 3002;
    };
    settings.mailer = {
      ENABLED        = true;
      FROM           = "Captain <captain@atlant.is>";
      PROTOCOL       = "smtps";
      SMTP_ADDR      = "smtp.free.fr";
      SMTP_PORT      = 587;
      USER           = "frederic.ruget";
      #PASSWD = builtins.readFile config.sops.secrets."captain/email_passwd".path;
    };
    mailerPasswordFile = config.sops.secrets."captain/email_passwd".path;
    settings.service = {
      DISABLE_REGISTRATION = true;
    };
  };

  security.acme.certs."gitea" = rec {
      domain = with { ng = config.custom.ngrok; };
        "gitea.${ng.prefix}${ng.host}";
      dnsProvider = "ovh";
      dnsPropagationCheck = true;
      credentialsFile = config.sops.secrets."ovh/credentials".path;
    };

  services.nginx.virtualHosts = {
    "gitea.${config.custom.ngrok.prefix}${config.custom.ngrok.host}" = {
      useACMEHost = "gitea";
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:3002";
    };
  };

  services.postgresql = {
    ensureDatabases = [ config.services.gitea.user ];
    ensureUsers = [
      {
        name = config.services.gitea.database.user;
        ensureDBOwnership = true;
      }
    ];
  };
}