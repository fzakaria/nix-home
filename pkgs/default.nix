# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{pkgs, ...}: {
  # example = pkgs.callPackage ./example { };

  # GPUI treemap explorer for disk usage, taken from unstable (not in
  # nixos-26.05) but built from my gnome-chrome-and-selection branch. Drop
  # the override once the branch is merged and released upstream.
  # https://github.com/fzakaria/disktree/tree/gnome-chrome-and-selection
  disktree = pkgs.unstable.disktree.overrideAttrs (prev: {
    version = "0.11.0-unstable-2026-11-19";
    src = pkgs.fetchFromGitHub {
      owner = "fzakaria";
      repo = "disktree";
      rev = "e1fdca809d2adbb83bacb6037266d31a892dba4f";
      hash = "sha256-mZpM37W51yqDzNKJCvwhG/K17xpf6mML/Q2MahwHJm8=";
    };
    cargoHash = "sha256-IC8xTYFrCIkKVSQsRB8I2jlRDYjjdvMf2GArd2O2jvs=";

    # The branch adds SSH scanning, which runs disktree-scan on the remote
    # host. Build it alongside the app so hosts using this config have it.
    cargoBuildFlags = prev.cargoBuildFlags ++ ["--package=disktree-scan"];

    # The branch's exported delete scripts refuse to run without findmnt, and
    # disktree-core's tests execute one.
    nativeCheckInputs = (prev.nativeCheckInputs or []) ++ [pkgs.unstable.util-linux];
  });
}
