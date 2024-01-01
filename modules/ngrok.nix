{ config, lib, pkgs, ... }:

with lib;

#let
#  cfg = config.ngrok.ngrok;
#in
{
  options.custom.ngrok = {
    enable = mkEnableOption "my custom module";

    prefix = mkOption {
      type = types.str;
    };

    host = mkOption {
      type = types.str;
    };

    port = mkOption {
      type = types.str;
    };

    #hostport = mkOption {
    #  type = types.int;
    #  #default = 10;
    #  #description = "description";
    #};
  };

  config = mkIf config.custom.ngrok.enable {
    #environment.systemPackages = with pkgs; [
    #  # Add here the system packages your module needs
    #];
    #
    ## Add here the configuration your module needs
    ## You can use 'cfg.setting1' and 'cfg.setting2'
  };
  
}
