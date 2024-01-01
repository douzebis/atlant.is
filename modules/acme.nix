# https://carjorvaz.com/posts/setting-up-wildcard-lets-encrypt-certificates-on-nixos/

{ config, lib, ... }:

{
  sops.secrets."ovh/credentials" = {
    sopsFile = ../secrets/ovh.yaml;
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "fred@atlant.is";
  };
}