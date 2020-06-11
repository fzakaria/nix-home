#!/usr/bin/env bash
#
# This scripts aims to detect which system is running, and bootstrap
# the home configuration accordingly. 
#   
# So far the current setup are supported:
# - Linux
# - Mac OSX
# 
# Inspiration from https://gitlab.com/vdemeester/home/-/blob/master/bootstrap.sh

# -e: will cause a bash script to exit immediately when a command fails.
# -o pipefail: the exit code of a pipeline to that of the rightmost command
#              to exit with a non-zero status, or to zero if all commands of the pipeline exit successfully.
# -u: treat unset variables as an error and exit immediately.
set -euo pipefail

# Install nix
setup_nix() {
    if hash nix 2>/dev/null; then
        echo "> nix already present"
    else
        echo "> Install nix"
        curl https://nixos.org/nix/install | sh
        source ~/.nix-profile/etc/profile.d/nix.sh
    fi
}

# Install home-manager
setup_home-manager() {
    if hash home-manager 2>/dev/null; then
        echo "> home-manager already present"
    else
        echo "> Install home-manager"
        nix-channel --add https://github.com/rycee/home-manager/archive/master.tar.gz home-manager
        nix-channel --update
        nix-shell '<home-manager>' -A install
    fi
}

setup_osx() {
    echo "> Mac OS X detected"

    echo "> Not supported at the moment."
    exit 1
}

setup_linux() {
    echo "> Linux detected"
}

setup_nix
setup_home-manager

# run the installation
source install.sh

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    setup_linux
elif [[ "$OSTYPE" == "darwin"* ]]; then
    setup_osx
else
    echo "> Unknown OS ${OSTYPE}"
    exit 1
fi