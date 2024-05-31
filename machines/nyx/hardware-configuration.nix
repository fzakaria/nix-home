# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{
  inputs,
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
  ];

  boot = {
    initrd = {
      availableKernelModules = ["nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod"];
      kernelModules = [];
    };
    kernelModules = ["kvm-amd"];
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = [];
    kernelParams = [
      # Turn on adaptive brightness management
      # https://community.frame.work/t/adaptive-backlight-management-abm/41055/31
      #  "amdgpu.abmlevel=0"
    ];
  };

  hardware = {
    opengl = {
      # enable Mesa
      enable = true;
      # enable Vulkan
      driSupport = true;
    };

    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
    "boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077"];
    };
  };

  swapDevices = [
    {device = "/dev/disk/by-label/swap";}
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp1s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
