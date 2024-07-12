{config, ...}: {
  programs.ssh = {
    # Community builder for Linux
    knownHosts."build-box.nix-community.org".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElIQ54qAy7Dh63rBudYKdbzJHrrbrrMXLYl7Pkmk88H";

    # nix remote builders don't work with Yubikey and on NixOS the builder runs as root
    # so what we do is tell it the user to login as but give it the identity agent to connect
    # to for my (fmzakari) user. A bit of a hack but....not sure a better alternative.
    extraConfig = ''
      Host build-box.nix-community.org
        IdentityAgent /run/user/1000/yubikey-agent/yubikey-agent.sock
    '';
  };

  # Load our remote builder agent for nixbuild
  # they don't support yubikey and only ssh-ed25519
  age.secrets = {
    "nixbuild.key" = {
      file = ./secrets/nixbuild.key.age;
    };
  };

  nix = {
    distributedBuilds = true;

    # Nix will instruct remote build machines to use their own binary substitutes if available.
    # In practical terms, this means that remote hosts will fetch as many build dependencies as
    # possible from their own substitutes (e.g, from cache.nixos.org), instead of waiting for this
    # host to upload them all. This can drastically reduce build times if the network connection
    # between this computer and the remote build host is slow.
    settings.builders-use-substitutes = true;

    buildMachines = [
      {
        protocol = "ssh-ng";
        hostName = "build-box.nix-community.org";
        maxJobs = 4;
        systems = ["x86_64-linux"];
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
        sshUser = "fmzakari";
      }
    ];
  };
}