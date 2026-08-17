# Personal Omarchy configuration. The reusable module that this builds on
# lives at modules/home-manager/omarchy.nix.
#
# Enablement follows the machine rather than being set here: a host that turns
# on services.omarchy gets the matching home configuration, and the hosts and
# standalone home configurations that do not stay untouched. That keeps
# `services.omarchy.enable = true` on the machine as the single switch.
{
  osConfig ? {},
  outputs,
  ...
}: {
  imports = [
    outputs.homeManagerModules.omarchy
  ];

  programs.omarchy = {
    enable = osConfig.services.omarchy.enable or false;
    theme = "tokyo-night";
  };
}
