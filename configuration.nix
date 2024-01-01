{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking = {
    hostName = "killy";
    useDHCP = false;
    interfaces.enp0s1.ipv4.addresses = [{
          address = "192.168.1.254";
          prefixLength = 24;
    }];
    defaultGateway = "192.168.1.1";
    nameservers = [
      "8.8.8.8"
      "8.8.4.4"
    ];
  };

  # Locales
  time.timeZone = "Europe/Paris";
  console.keyMap = "fr";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_MESSAGES = "en_US.UTF-8";
      LC_MEASUREMENT = "fr_FR.UTF-8";
      LC_TIME = "fr_FR.UTF-8";
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # Create hashed passwords as follows:
  # mkpasswd -m sha-512 "$(read -s s && echo -n $s)" "$(cat /dev/urandom | LC_ALL=C tr -dc 'a-z' | head -c 16)"
  users.mutableUsers = false; # Required for NixOS to enforce hashed passwords
  users.users.fred = {
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPm+duRHtVfoxhpDrkdSeoJ6pvvSCALQoyblR7hPdNoS"];
    isNormalUser = true;
    hashedPassword = "$6$bxhsnftiyevtsraa$beLpXBZYm6CMTsiHQ0l7L.y8SFQGtJ/2jIlv5J1kGy7xWGMO7TDlD2RBFMaVA2yo/eY4aVMuSEiuMIM0UtnRb1";
    uid = 1000;
    extraGroups = [ "fred" "wheel" ]; # Enable ‘sudo’ for the user.
  };
  users.users.root = {
    hashedPassword = "$6$mlcenqypkntlpbqm$9JSGrgJR74oYtFvqHNnzMWI90taZj1LgJlZhrQodVgMYe.rqCY7iXJzH/y/YUC.Nkal2GfqCs82zueDSV055Q1";
  };
  users.extraGroups.fred = {
    gid = 1000;  # Choose a unique group ID
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "ngrok"
  ];
  environment.systemPackages = with pkgs; [
    age
    bind
    curl
    file
    git
    moreutils
    ngrok
    nodejs
    pkgs.jq
    python3
    sops
    wget
  ];

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  systemd.services.keycloakExportRealms =
  let p = config.systemd.services.keycloak;
  in lib.mkIf config.services.keycloak.enable {
    after = p.after;
    before = [ "keycloak.service" ];
    wantedBy = [ "multi-user.target" ];
    environment = lib.mkForce p.environment;
    serviceConfig =  let origin = p.serviceConfig; in {
        Type = "oneshot";
        RemainAfterExit = false;
        User = origin.User;
        Group = origin.Group;
        LoadCredential = origin.LoadCredential;
        DynamicUser =  origin.DynamicUser;
        RuntimeDirectory = origin.RuntimeDirectory;
        RuntimeDirectoryMode = origin.RuntimeDirectoryMode;
        AmbientCapabilities = origin.AmbientCapabilities;
        StateDirectory = "keycloak";
        StateDirectoryMode = "0750";
    };
    script = ''
          ${lib.strings.removeSuffix "kc.sh start --optimized\n" config.systemd.services.keycloak.script}
            EDIR="/var/lib/keycloak"
            EDIRT="$EDIR/$(date '+%Y/%m/%d/%H:%M:%S')"
            mkdir -p $EDIRT
            kc.sh export --optimized --dir=$EDIRT
      '';
  };

  # Enable Flakes and the new command-line tool
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?
}
