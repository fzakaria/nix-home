{inputs, ...}: {
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];

  # Enable the NixOS module for NixVim
  # Many thanks to https://github.com/dc-tec/nixvim
  programs.nixvim = {
    enable = true;

    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    globals = {
      # Set the leader key to space
      mapleader = " ";
    };

    diagnostic = {
      settings = {
        virtual_text = true;
      };
    };

    opts = {
      # Show line numbers
      number = true;
      # Show relative line numbers
      relativenumber = true;
      # Use the system clipboard
      clipboard = "unnamedplus";
      # Number of spaces that represent a <TAB>
      tabstop = 2;
      softtabstop = 2;
      # Show tabline always
      showtabline = 2;
      # Use spaces instead of tabs
      expandtab = true;
      # Number of spaces to use for each step of (auto)indent
      shiftwidth = 2;
      # Enable smart indentation
      smartindent = true;
      # Enable break indent
      breakindent = true;
      # Highlight the screen line of the cursor
      cursorline = true;
      # Enable mouse support
      mouse = "a";
      # Minimum number of screen lines to keep above and below the cursor
      scrolloff = 8;
      # Wrap long lines at a character in 'breakat'
      linebreak = true;
      # Enable 24-bit RGB color in the TUI
      termguicolors = true;
    };

    colorschemes = {
      dracula-nvim = {
        enable = true;
      };
    };

    plugins = {
      # https://github.com/nvim-telescope/telescope.nvim
      telescope = {
        enable = true;
        keymaps = {
          "<leader><space>" = {
            action = "find_files";
            options = {
              desc = "Find project files";
            };
          };
          "<leader>/" = {
            action = "live_grep";
            options = {
              desc = "Live grep";
            };
          };
          "<leader>b" = {
            action = "buffers";
            options = {
              desc = "+buffer";
            };
          };
          "<leader>h" = {
            action = "help_tags";
            options = {
              desc = "Help pages";
            };
          };
        };
      };

      # https://github.com/nvim-treesitter/nvim-treesitter/
      treesitter = {
        enable = true;
        settings = {
          indent.enable = false;
          highlight.enable = true;
        };
      };

      # https://github.com/nvim-neo-tree/neo-tree.nvim
      neo-tree = {
        enable = true;
        filesystem = {
          followCurrentFile = {
            enabled = true;
          };
        };
      };

      web-devicons = {
        enable = true;
      };

      # show available keybindings in a popup as you type
      # https://github.com/folke/which-key.nvim
      which-key = {
        enable = true;
      };

      lualine = {
        enable = true;
        settings = {
          options = {
            globalStatus = true;
            theme = "dracula";
          };
        };
      };

      lsp = {
        enable = true;
        inlayHints = true;
        servers = {
          nixd = {
            enable = true;
          };
        };
      };

      # https://github.com/neovim/nvim-lspconfig/
      # provides default configs for many language servers
      lspconfig = {
        enable = true;
      };

      # Indent guides for Neovim
      # https://github.com/lukas-reineke/indent-blankline.nvim
      indent-blankline = {
        enable = true;
        luaConfig.pre = ''
          local hooks = require('ibl.hooks')
          -- create the highlight groups in the highlight setup hook, so they are reset
          -- every time the colorscheme changes
          hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
              vim.api.nvim_set_hl(0, 'RainbowRed', { fg = '#E06C75' })
              vim.api.nvim_set_hl(0, 'RainbowYellow', { fg = '#E5C07B' })
              vim.api.nvim_set_hl(0, 'RainbowBlue', { fg = '#61AFEF' })
              vim.api.nvim_set_hl(0, 'RainbowOrange', { fg = '#D19A66' })
              vim.api.nvim_set_hl(0, 'RainbowGreen', { fg = '#98C379' })
              vim.api.nvim_set_hl(0, 'RainbowViolet', { fg = '#C678DD' })
              vim.api.nvim_set_hl(0, 'RainbowCyan', { fg = '#56B6C2' })
          end)
        '';
        settings = let
          highlight = [
            "RainbowRed"
            "RainbowYellow"
            "RainbowBlue"
            "RainbowOrange"
            "RainbowGreen"
            "RainbowViolet"
            "RainbowCyan"
          ];
        in {
          scope = {
            enabled = true;
            char = "▎";
            inherit highlight;
            include.node_type = {
              # show scopes for attrsets
              nix = ["attrset_expression"];
            };
          };
          indent = {
            char = "┊";
            tab_char = "┊";
            inherit highlight;
          };
        };
      };
    };
  };
}
