{
  inputs,
  outputs,
  config,
  pkgs,
  ...
}: {
  imports = [
    # Import home-manager's NixOS module
    inputs.home-manager.nixosModules.home-manager
  ];

  # useful NixOS home-manager settings
  home-manager = {
    # By default packages will be installed to $HOME/.nix-profile
    # but they can be installed to /etc/profiles if useUserPackages is true
    # This is necessary if, for example, you wish to use nixos-rebuild build-vm
    useUserPackages = true;

    # By default, Home Manager uses a private pkgs instance that is configured via the home-manager.users.<name>.nixpkgs options.
    # To instead use the global pkgs that is configured via the system level nixpkgs options, set
    useGlobalPkgs = true;

    # make inputs and outputs available to home-manager
    extraSpecialArgs = {inherit inputs outputs;};
  };

  # TODO(fzakaria): Eventually we want to make this declarative
  # users.mutableUsers = false;

  # enable Zsh for users that use it
  # so that home-manager shells can get completion
  environment.pathsToLink = ["/share/zsh" "/share/fish" "/share/bash"];
  programs = {
    zsh.enable = true;
    fish.enable = true;
  };

  users.extraUsers.fmzakari = {
    # This automatically sets group to users, createHome to true,
    # home to /home/username, useDefaultShell to true, and isSystemUser to false
    isNormalUser = true;
    # I actually want to use fish but I have gotten bitten too many times at this
    # point with fish incompatibilities since many things default to SHELL
    # Let's have our login shell be bash and just manually enter fish :(
    shell = pkgs.bash;
    extraGroups = ["wheel" "networkmanager" "scanner" "lp" "docker"];
    description = "Farid Zakaria";
    openssh.authorizedKeys.keyFiles = [
      ./fmzakari/keys
    ];
  };

  home-manager.users.fmzakari = import ../users/fmzakari;

  # only ask for password every 1h
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=60
  '';

  users.extraUsers.mrw = {
    isNormalUser = true;
    shell = pkgs.bash;
    extraGroups = ["wheel" "networkmanager"];
    description = "Mark Williams";
    openssh.authorizedKeys.keyFiles = [
      ./mrw/keys
    ];
    packages = with pkgs; [
      brightnessctl
      comma
      discord
      dmenu
      docker
      emacs
      firefox
      flameshot
      (haskellPackages.ghcWithPackages (hpkgs: [
        hpkgs.xmonad
        hpkgs.xmonad-contrib
      ]))
      killall
      man-pages
      pass
      pavucontrol
      polybarFull
      python3
      rxvt-unicode
      rustup
      signal-desktop
      virtualenv
      wmctrl
      vscode
      xcalib
    ];
  };
}
