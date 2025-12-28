# Place common home-manager setup here
{
  inputs,
  pkgs,
  lib,
  config,
  osConfig,
  ...
}: {
  imports = [
    ./git.nix
    ./fish.nix
    ./vscode.nix
    ./helix.nix
    ./vim
    inputs.h.homeModules.default
    inputs.nix-index-database.homeModules.nix-index
  ];

  home = {
    username = "fmzakari";
    homeDirectory = "/home/fmzakari";
  };

  # nix-shell uses config.nix file, ideally we should keep it in sync
  # with config.nixpkgs.config but accessing osConfig from home-manager won't
  # work nicely on non-NixOS systems
  xdg.configFile."nixpkgs/config.nix".text = ''
    { allowUnfree = true; }
  '';

  # List of additional package outputs of the packages home.packages
  # that should be installed into the user environment.
  home.extraOutputsToInstall = ["man" "doc" "info" "devdoc"];
  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.09";

  home.sessionVariables = {
    LESS = "--quit-if-one-screen --RAW-CONTROL-CHARS";
    # this is now set by nixvim
    # EDITOR = "vim";
    # TODO(fmzakari): I might want this if I use home-manager on Linux non-NixOS
    # https://nixos.org/manual/nixpkgs/stable/#locales
    # LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
  };

  # Place packages here that are
  home.packages = with pkgs; [
    # unzip
    unzip
    # dig
    dig
    # tree
    tree
    # a tool to help review other nixpkgs PR requests
    nixpkgs-review
    # age is a simple, modern and secure file encryption tool, format, and library.
    # https://github.com/FiloSottile/age
    age
    # A simple, fast and user-friendly alternative to 'find'
    # https://github.com/sharkdp/fd
    fd
    # ripgrep recursively searches directories for a regex pattern
    # https://github.com/BurntSushi/ripgrep
    ripgrep
    # Quickly locate nix packages with specific files
    # https://github.com/bennofs/nix-index
    # TODO(fzakaria): We bring it in with nix-index-database as a NixOS module
    # nix-index
    # Command line tool to share your UNIX terminal and forward local TCP ports to people you trust.
    # https://github.com/gravitational/teleconsole
    # archived by upstream
    #teleconsole
    cachix
    # Terminal session recorder
    # https://github.com/asciinema/asciinema
    asciinema
    # Command-line JSON processor
    # https://github.com/stedolan/jq
    jq
    # htop is an interactive text-mode process viewe
    # https://github.com/hishamhm/htop
    htop
    # A formatter for Nix code
    # https://github.com/kamadorueda/alejandra
    alejandra
    # A command-line fuzzy finder
    # https://github.com/junegunn/fzf
    fzf
    # TUI: Interactively browse dependency graphs of Nix derivations
    # https://github.com/utdemir/nix-tree
    nix-tree
    # Get additional information while building.
    # https://github.com/maralorn/nix-output-monitor
    nix-output-monitor
    # Add readelf and other common utilities
    # Add higher priority because it has some collisions with GCC on Darwin
    (lib.hiPrio binutils)
    # Add patchelf
    patchelf
    # Add gnumake
    gnumake
    # https://github.com/sharkdp/hyperfine
    # CLI benchmarking tool
    hyperfine
    # get copy and paste working for X11
    xclip
    niv
    buildifier
    just
    # Add compiler tools
    gcc
    # Use age with yubikey
    # https://github.com/str4d/age-plugin-yubikey
    age-plugin-yubikey
    # clangd and other tools
    clang-tools
    # Language Server for Nix
    # https://github.com/nix-community/nixd
    unstable.nixd
    # Add JDK
    openjdk
    maven
    gradle
    # Golang
    go
    # https://github.com/martinvonz/jj
    unstable.jujutsu
    unstable.zed-editor
    nixfmt-rfc-style
    zip
    ccache
    # Should we use the -bin variant?
    unstable.gemini-cli-bin
  ];

  programs = {
    # Let Home Manager install and manage itself.
    home-manager = {
      enable = true;
    };

    zellij = {
      enable = true;
      # Turns out starting Zellij on creation is kind of annoying
      # disable it.
      enableFishIntegration = false;
      enableZshIntegration = false;
      settings = {
        theme = "dracula";
        copy_command = "xclip -selection clipboard";
      };
    };

    # https://github.com/zimbatm/h
    # Faster code checkout
    h = {
      codeRoot = "~/code";
    };
    # A cd command that learns - easily navigate directories from the command line
    # https://github.com/wting/autojump
    # TODO(fzakaria): Completion does not seem to work.
    # I include sourcing the zsh autocomplete fucntions but it produces double underscore
    # https://github.com/wting/autojump/issues/692
    autojump = {
      enable = true;
    };

    bat = {
      enable = true;
      config = {
        theme = "Dracula";
      };
    };

    # A modern version of ls written in rust
    # https://github.com/eza-community/eza
    eza = {
      enable = true;
      icons = "never";
      git = true;
      enableFishIntegration = true;
    };

    direnv = {
      enable = true;
      config = {
      };
      nix-direnv.enable = true;
    };

    ssh = {
      enable = true;
      forwardAgent = true;
      # TODO(fzakaria): Doesn't exist in 23.05 nixos release
      # addKeysToAgent = "confirm";
      serverAliveInterval = 0;
      controlMaster = "auto";
      controlPersist = "60m";

      matchBlocks = {
        "alakwan" = {
          hostname = "alakwan.tail9f4b5.ts.net";
          user = "fzakaria";
        };
        "leviathan" = {
          hostname = "leviathan.cymric-daggertooth.ts.net";
          user = "fmzakari";
        };
      };
    };

    ghostty = {
      package = pkgs.unstable.ghostty;
      settings = {
        theme = "Dracula";
      };
    };

    # nix-index provides it's own command-not-found functionality
    nix-index.enable = true;
    nix-index-database.comma.enable = true;

    # A command-line fuzzy finder
    # https://github.com/junegunn/fzf
    fzf = {
      enable = true;
      changeDirWidgetCommand = "fd --color always --hidden --follow --exclude .git --type d";
      changeDirWidgetOptions = ["--ansi --preview 'exa --color always --tree {} | head -500'"];
      fileWidgetCommand = "fd --color always --type f --hidden --follow --exclude .git";
      fileWidgetOptions = [
        "--ansi --preview-window=right:60% --preview 'bat --style=plain --color=always --line-range :500 {}'"
      ];
    };

    jujutsu = {
      enable = true;
      package = pkgs.unstable.jujutsu;
      settings = {
        user = {
          name = "Farid Zakaria";
          email = "farid.m.zakaria@gmail.com";
        };

        revset-aliases = {
          # see jj bump & jj tug aliases
          "bumpable()" = "all:mutable() & mine()";
          "tuggable()" = "heads(::@- & bookmarks())";
        };

        aliases = {
          all = ["log" "-r" "all()"];
          bump = [
            "rebase"
            "-b"
            "bumpable()"
            "-d"
            "trunk()"
          ];
          tug = [
            "bookmark"
            "move"
            "--from"
            "tuggable()"
            "--to"
            "@-"
          ];
        };
      };
    };

    atuin = {
      # for now let's prefer fzf
      enable = false;
      package = pkgs.unstable.atuin;
      enableFishIntegration = true;
      settings = {
        update_check = false;
        key_path = osConfig.age.secrets."atuin.key".path;
        enter_accept = false;
        filter_mode = "session";
        filter_mode_shell_up_key_binding = "directory";
        style = "compact";
        # Has some UI issues
        # https://github.com/atuinsh/atuin/issues/1289
        inline_height = 20;
      };
    };

    bash = {
      enable = true;
      initExtra = ''
        # I have had so much trouble running fish as my login shell
        # instead run bash as my default login shell but just exec into it.
        # Check if the shell is interactive.
        if [[ $- == *i* && -z "$NO_FISH_BASH" && -z "$IN_NIX_SHELL" ]]; then
          exec ${pkgs.fish}/bin/fish
        fi
      '';
    };
  };
}
