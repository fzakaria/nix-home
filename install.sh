#!/usr/bin/env bash

set -euxo pipefail

home-manager switch --file ./home.nix $@
