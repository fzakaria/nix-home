# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  # anubis-fetch now lives in its own repo, consumed as a flake input:
  # https://github.com/fzakaria/anubis-fetch
}
