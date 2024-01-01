# https://carjorvaz.com/posts/setting-up-wildcard-lets-encrypt-certificates-on-nixos/

{ config, lib, ... }:

{
  sops.secrets."ovh/credentials" = {
    sopsFile = ../secrets/ovh.yaml;
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "fred@atlant.is";

    #certs."wildcardDomain" = rec {
    #  #domain = config.services.keycloak.settings.hostname;
    #  #domain = "2.ruget.org";
    #  domain = config.custom.ngrok.host;
    #  extraDomainNames = [ "*.${domain}" ];
    #  dnsProvider = "ovh";
    #  dnsPropagationCheck = true;
    #  credentialsFile = config.sops.secrets."ovh/credentials".path;
    #};
  };
}