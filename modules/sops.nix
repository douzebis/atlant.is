  # Age and SOPS initialization:
  #
  # Resources:
  # - https://github.com/Mic92/sops-nix/blob/f7db64b88dabc95e4f7bee20455f418e7ab805d4/README.md
  #
  # Create the master age private key and store it in user root's config
  # sudo mkdir -p /root/.config/sops/age
  # #sudo age-keygen -o /root/.config/sops/age/keys.txt
  # sudo nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key > /root/.config/sops/age/keys.txt"
  #
  # Create the sops configuration file including the master age public key and
  # store it at the root of the NixOS configuration files
  # sudo sponge /etc/nixos/.sops.yaml <<EOF
  # keys:
  #   - &admin_killy $(nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age')
  # creation_rules:
  #   - path_regex: .secrets/[^/]+\.yaml$
  #     key_groups:
  #     - age:
  #       - *admin_killy
  # EOF
  #
  # Create a secrets file in the clear
  # sudo sponge /etc/nixos/secrets/keycloak.yaml <<EOF 
  # keycloak:
  #   db_password: $(cat /dev/urandom | LC_ALL=C tr -dc 'a-z' | head -c 16)
  # EOF
  #
  # Encrypt the secrets file
  # (cd /etc/nixos && sudo sops --encrypt -i secrets/keycloak.yaml)
  #
  # Decrypt a secrets file
  # sudo sops -d /etc/nixos/secrets/keycloak.yaml
  #
  # Edit a secrets file and encrypt after the editor exits
  # (cd /etc/nixos && sudo sops secrets/keycloak.yaml)
