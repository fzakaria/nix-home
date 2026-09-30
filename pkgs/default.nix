# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{pkgs, ...}: {
  # example = pkgs.callPackage ./example { };

  # GPUI treemap explorer for disk usage; not in nixpkgs yet.
  # Built from unstable because upstream requires rust >= 1.97.
  # https://github.com/tobi/disktree
  disktree = pkgs.unstable.callPackage ./disktree/package.nix {};
}
