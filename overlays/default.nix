# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # We want to use the yubikey-agent so disable gnome's ssh-agent
    gnome = prev.gnome.overrideScope (gfinal: gprev: {
      gnome-keyring = gprev.gnome-keyring.overrideAttrs (oldAttrs: {
        enableParallelBuilding = true;

        configureFlags =
          oldAttrs.configureFlags
          or []
          ++ [
            "--disable-ssh-agent"
          ];
      });
    });

    tailscale = prev.tailscale.overrideAttrs (old: {
      subPackages =
        old.subPackages
        ++ [
          "cmd/proxy-to-grafana"
        ];
    });

    # TODO(fzakaria): These should from an overlay from the flake.
    # Checkphase with emulation takes a very long time. For now disable it.
    tclip = inputs.tailscale-tclip.packages."${prev.system}".tclip.overrideAttrs (oldAttrs: {
      doCheck = false;
    });
    tclipd = inputs.tailscale-tclip.packages."${prev.system}".tclipd.overrideAttrs (oldAttrs: {
      doCheck = false;
    });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
