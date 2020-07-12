# Nix Home

Welcome to a development environment using Nix; specifically with [HomeManager](https://rycee.gitlab.io/home-manager/).

## Nix

Nix is a totally different way of managing packages & dependencies on your machine from all other package managers: homebrew, apt, yum etc..

If you want the official explanation on what Nix does better please read [why you should give it a try](https://nixos.org/nixos/nix-pills/why-you-should-give-it-a-try.html).

> Nix is a purely functional package manager. This means that it treats packages like values in purely functional programming languages such as Haskell — they are built by functions that don’t have side-effects, and they never change after they have been built. - [About Nix](https://nixos.org/nix/about.html)

## Getting Started

You can git clone this repository wherever you'd like!
Don't forget to update the submodules
```bash
git submodule init 
git submodule update
```

### Backup Files
Athough this tool will **try it's best** not to clobber any files outside it's management; it's best just to backup any files before on-boarding.

```bash
mv ~/.zshrc ~/.zshrc.bak
mv ~/.gitconfig ~/.gitconfig.bak
mv ~/.p10k.zsh ~/.p10k.zsh.bak
mv ~/.rbenv ~/.rbenv.bak
mv ~/.config/htop/htoprc ~/.config/htop/htoprc.bak
mv ~/.ssh/config ~/.ssh/config.bak
mv ~/.tmux.conf ~/.tmux.conf.bak
mv ~/.tmux.conf.local ~/.tmux.conf.local.bak
mv ~/.vimrc ~/.vimrc.bak 
```

### Bootstrap
The first time using _nix-home_ you simply need to run `./bin/bootstrap` **once**.
It will take care of installing Nix.

### Updating

Subsequent updating to the repository can be reflected in your system by simply running `./bin/switch`

### Uninstall

You can uninstall by running:

```bash
# remove the . "$HOME/.nix-profile/etc/profile.d/nix.sh" line in your ~/.profile or ~/.bash_profile
rm -rf $HOME/{.nix-channels,.nix-defexpr,.nix-profile,.config/nixpkgs}
rm -rf /nix
 ```

 > Don't forget to move back all your backup dotfiles!
