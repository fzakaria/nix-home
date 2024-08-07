# Nix Home

Welcome to a our declarative machine setup using Nix.

## NixOS Machines

[nyx](./machines/nyx/configuration.nix): Framework Laptop 13 AMD whose primary driver is [fzakaria](https://github.com/fzakaria).

[nixie](./machines/nixie/configuration.nix): Framework Laptop 13 AMD whose primary driver is [markrwilliams](https://github.com/markrwilliams).

[altaria](./machines/altaria/configuration.nix): AWS EC2 server running a few things, namely quassel.

## HomeManager

Additionally, we keep a few HomeManager only setups.
You can find them in [flake.nix](./flake.nix).

## Why Nix/NixOS?

Nix is a totally different way of managing packages & dependencies on your machine from all other package managers: homebrew, apt, yum etc..

If you want the official explanation on what Nix does better please read [why you should give it a try](https://nixos.org/nixos/nix-pills/why-you-should-give-it-a-try.html).