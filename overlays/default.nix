# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # TODO(fzakaria): These should from an overlay from the flake.
    # Checkphase with emulation takes a very long time. For now disable it.
    tclip = inputs.tailscale-tclip.packages."${prev.stdenv.hostPlatform.system}".tclip.overrideAttrs (oldAttrs: {
      doCheck = false;
    });
    tclipd = inputs.tailscale-tclip.packages."${prev.stdenv.hostPlatform.system}".tclipd.overrideAttrs (oldAttrs: {
      doCheck = false;
    });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
}
