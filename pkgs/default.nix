# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: let
  anubis-solve = pkgs.callPackage ./anubis-solve {};
in {
  # example = pkgs.callPackage ./example { };
  inherit anubis-solve;
  # anubis-fetch is the main CLI: it runs anubis-solve first, then falls back to
  # a headless browser. Wire the dependency explicitly so it resolves even when
  # building the flake's `packages` output directly (where the `additions`
  # overlay isn't applied to `pkgs`).
  anubis-fetch = pkgs.callPackage ./anubis-fetch {inherit anubis-solve;};
}
