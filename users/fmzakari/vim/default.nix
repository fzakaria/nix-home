{inputs, ...}: {
  imports = [
    inputs.nixvim.homeModules.nixvim
  ];

  # Enable the NixOS module for NixVim
  # Many thanks to https://github.com/dc-tec/nixvim
  programs.nixvim = {
    enable = true;
    nixpkgs = {
      config = {
        allowUnfree = true;
      };
    };

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

    keymaps = [
      {
        mode = ["n"];
        key = "<leader>e";
        action = "<cmd>Neotree reveal toggle<cr>";
        options = {
          desc = "Toggle Neotree";
        };
      }
      {
        key = "<leader>bd";
        action = "<cmd>lua MiniBufremove.delete()<cr>";
        options = {
          desc = "Close Buffer";
        };
      }
      # Quickly save the current buffer
      {
        mode = ["n" "i" "v"];
        key = "<C-s>";
        action = "<cmd>w<CR>";
        options = {
          noremap = true;
          silent = true;
        };
      }
      # Trigger auto completion box
      {
        mode = "i";
        key = "<C-Space>";
        action = "<C-x><C-o>";
        options = {
          noremap = true;
          silent = true;
        };
      }
    ];

    plugins = {
      # https://github.com/nvim-telescope/telescope.nvim
      telescope = {
        enable = true;
        extensions = {
          file-browser = {
            enable = true;
          };
          fzf-native = {
            enable = true;
          };
        };
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
          "<leader>ff" = {
            action = "find_files";
            options = {
              desc = "Find project files";
            };
          };
          "<leader>fr" = {
            action = "oldfiles";
            options = {
              desc = "Recent";
            };
          };
          "<leader>fb" = {
            action = "buffers";
            options = {
              desc = "+buffer";
            };
          };
          "<leader>sb" = {
            action = "current_buffer_fuzzy_find";
            options = {
              desc = "Buffer";
            };
          };
          "<leader>sk" = {
            action = "keymaps";
            options = {
              desc = "Keymaps";
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

      mini = {
        enable = true;
        modules = {
          basics = {
            mappings = {
              windows = true;
            };
          };
          bufremove = {};
        };
      };

      copilot-vim = {
        enable = true;
      };

      web-devicons = {
        enable = true;
      };

      # show available keybindings in a popup as you type
      # https://github.com/folke/which-key.nvim
      which-key = {
        enable = true;
      };

      # https://github.com/windwp/nvim-autopairs
      nvim-autopairs = {
        enable = true;
      };

      bufferline = {
        enable = true;
        settings = {
          options = {
            mode = "buffers";
            diagnostics = "nvim_lsp";
            offsets = [
              {
                filetype = "neo-tree";
                text = "Neo-tree";
                highlight = "Directory";
                text_align = "left";
              }
            ];
          };
        };
      };

      lualine = {
        enable = true;
        settings = {
          options = {
            extensions = [
              "fzf"
              "neo-tree"
            ];
            globalstatus = true;
            theme = "dracula";
          };
          sections = {
            lualine_x = [
              # let's hide copilot as it's always active
              {
                __unkeyed = "lsp_status";
                ignore_lsp = ["GitHub Copilot"];
              }
              "filetype"
              "hostname"
            ];
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
          clangd = {
            enable = true;
          };
          pyright = {
            enable = true;
          };
          ts_ls = {
            enable = true;
          };
          gopls = {
            enable = true;
          };
        };
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
              nix = [
                "list_expression"
                "attrset_expression"
                "rec_attrset_expression"
              ];
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
