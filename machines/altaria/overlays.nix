# Overlays that apply to altaria only, for package tweaks that make no sense on
# the other machines. Wired in by the `machine` helper in flake.nix, so this
# file exists for every host -- an empty list is the normal state.
#
# `nixpkgs.overlays` is a list option, so what is added here is appended to
# the shared overlays applied in modules/nixpkgs.nix rather than replacing
# them. Machine overlays are applied last, which means they see (and can
# override) whatever the shared overlays defined.
#
# An entry looks like:
#
#   (_final: prev: {
#     some-package = prev.some-package.overrideAttrs (oldAttrs: {...});
#   })
_: {
  nixpkgs.overlays = [
  ];
}
