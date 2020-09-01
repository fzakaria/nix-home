{ config, pkgs, ... }:
let nixpkgs = (import ../../nix/sources.nix).nixos;
in {
  imports = [
    ./hardware-configuration.nix
    (nixpkgs + "/nixos/modules/virtualisation/amazon-image.nix")
    ../../modules/common.nix
    ../../modules/platforms/nixos.nix
  ];

  users.extraUsers.fmzakari = {
    # This automatically sets group to users, createHome to true,
    # home to /home/username, useDefaultShell to true, and isSystemUser to false
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [''
      ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC6rdr4W0yak9JO48bf4B342rl7+8iupOQXuCZMZaenbyOu/qgPth//5j3vm+1OlprfktywzXT5TbfgzzCdvZIkvA7Q6lUgLc6cohU5JXpfpvvMUtEtxMC6RnHBHsOrm9rxeUSdiA7X7ZvjlnBsxH3R9e4nTWYThX6mXkMOevdFIxSGlrtdCSZyysngd0J7Kb4WeR6WsF/PFO6b/b0ag6ovr0i4P9/76lCrsGa1/ee042B950H3iZtIfnU80Y98fk59/6ZD7zI13WtFvocAxBvlwwj3DmGAPnt6Pgc7Jgr89MEPMRGbIlxL+EiVX3/OjguA/giBv4k00FZdZV2zaK/264YKgcZYSpnWmrju56IKRjtScZrxitFcOMHUt0SKEL5wQ8mZ2bDWLUcLyvkLlocv0+2Qn4DivOPMSQDHYLmVIqIjWdgi5s+WzbQ0PW9xM2N7x7YfzSKo1HXmL/q9LvvjpiZ9cerXevpInrszDZJ2gwQ9nsiVr588XILT4YdQUAmJU4sZbXXQeeLQvVMTJZTNo0NplyPhOLwZHmd+UhL8fVJHvDgEpxP4soVbyfeUwTwJ8sRKPZKvZOuijkYwSa18rfoCNZFstqvAJ4h6AJJnE9APqMORlGQa82S0lC9xkMuPZR/mCJrgqzvM/jeymfSNdNjzAtuIQCIxaYX7tycNWw==
    ''];
  };

  home-manager.users.fmzakari = import ../../modules/home-manager.nix;

}
