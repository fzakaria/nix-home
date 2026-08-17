# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory.
  # `inputs` goes along because some packages are built from a flake input
  # that is a bare source tree, such as the Omarchy checkout.
  additions = final: _prev:
    import ../pkgs {
      pkgs = final;
      inherit inputs;
    };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # Claude Code from numtide's llm-agents.nix (tracks upstream more
    # aggressively than nixpkgs). Exposed here so `pkgs.claude-code` is available
    # everywhere -- claude.nix wraps it with LSP servers, and b4's review-agent
    # command references the same binary. https://github.com/numtide/llm-agents.nix
    claude-code = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system}.claude-code;

    # TODO(fzakaria): These should from an overlay from the flake.
    # Checkphase with emulation takes a very long time. For now disable it.
    tclip = inputs.tailscale-tclip.packages."${prev.stdenv.hostPlatform.system}".tclip.overrideAttrs (oldAttrs: {
      doCheck = false;
    });
    tclipd = inputs.tailscale-tclip.packages."${prev.stdenv.hostPlatform.system}".tclipd.overrideAttrs (oldAttrs: {
      doCheck = false;
    });

    # herdr, the agent runtime Omarchy binds SUPER+H to. Surfaced as a plain
    # package so modules/nixos/omarchy.nix can name it without reaching for
    # flake inputs, the same way claude-code above is handled.
    herdr = inputs.herdr.packages.${prev.stdenv.hostPlatform.system}.herdr;

    # tobi's `try`, shipped as tobi-try in Omarchy's package list.
    try = inputs.try.packages.${prev.stdenv.hostPlatform.system}.default;
  };

  # When applied, an unstable nixpkgs set is accessible through 'pkgs.unstable'.
  unstable-packages = final: _prev: {
    unstable =
      (inputs.multiverse.lib.mkMultiverse {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
        overlays = [inputs.nix-vscode-extensions.overlays.default];
      })
      .tip;
  };
}
