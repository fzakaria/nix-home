let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {
    overlays = [
      (_: super: {
        niv = (super.callPackage (import sources.niv) { }).niv;
        home-manager =
          (super.callPackage (import sources.home-manager) { }).home-manager;
      })
    ];
  };
in with pkgs;
mkShell {
  name = "nix-home-shell";
  buildInputs = [ niv nixfmt home-manager ];
}
