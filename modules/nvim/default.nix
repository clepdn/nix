{ pkgs, lib, ... }:
{
  programs.nixvim = {
    enable = true;

    globals = {
      mapleader = "\\";
      maplocalleader = "\\";
      markdown_fenced_languages = [ "ts=typescript" "tsx=typescript" ];
    };

    opts = {
      relativenumber = true;
      number = true;
      splitright = true;
      showtabline = 2;
    };

    # OSC 52 clipboard + post-load setup
    extraConfigLua = ''
      vim.g.clipboard = {
        name = 'OSC 52',
        copy = {
          ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
          ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
        },
        paste = {
          ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
          ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
        },
      }

      vim.lsp.inlay_hint.enable(true)

      vim.cmd('colorscheme evergarden-winter')

      require('tabby').setup({
        preset = 'active_wins_at_tail',
        option = {
          theme = {
            fill = 'TabLineFill',
            head = 'TabLine',
            current_tab = 'TabLineSel',
            tab = 'TabLine',
            win = 'TabLine',
            tail = 'TabLine',
          },
          nerdfont = true,
          buf_name = {
            mode = 'unique',
            override = function(bufid)
              if vim.bo[bufid].buftype == 'terminal' then
                return '󰈺 fish'
              end
            end,
          },
        },
      })
    '';

    keymaps = [
      {
        mode = "t";
        key = "<C-Esc>";
        action = "<C-\\><C-n>";
        options.desc = "Exit terminal mode";
      }
      {
        mode = "n";
        key = "<leader>i";
        action.__raw = "function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end";
        options.desc = "Toggle inlay hints";
      }
      {
        mode = "n";
        key = "<leader>d";
        action.__raw = "function() vim.diagnostic.open_float() end";
      }
      {
        mode = "n";
        key = "<leader>D";
        action = "<cmd>Telescope diagnostics bufnr=0<cr>";
        options.desc = "List diagnostics in current buffer";
      }
      {
        mode = "n";
        key = "<leader>f";
        action.__raw = "function() require('telescope').extensions.file_browser.file_browser() end";
        options.noremap = true;
      }
      {
        mode = "n";
        key = "<leader>bf";
        action = "<cmd>Telescope buffers<cr>";
        options.desc = "Find buffers";
      }
      {
        mode = "n";
        key = "<leader>h";
        action.__raw = "vim.lsp.buf.hover";
        options.desc = "LSP Hover";
      }
      {
        mode = "n";
        key = "<leader>rn";
        action.__raw = "vim.lsp.buf.rename";
      }
      {
        mode = "n";
        key = "gy";
        action = ":tabp<CR>";
        options = { noremap = true; silent = true; };
      }
      {
        mode = [ "v" "n" ];
        key = "<leader>m";
        action = "<cmd>MCstart<cr>";
        options.desc = "Multi-cursor on word/selection";
      }
    ];

    plugins = {
      web-devicons.enable = true;
      telescope = {
        enable = true;
        extensions.file-browser.enable = true;
      };

      lsp = {
        enable = true;
        servers = {
          rust_analyzer = {
            enable = true;
            installCargo = false;
            installRustc = false;
            settings = {
              "rust-analyzer" = {
                diagnostics.enable = true;
                inlayHints = {
                  enable = true;
                  chainingHints.enable = true;
                  typeHints = {
                    enable = true;
                    hideClosureInitialization = false;
                    hideNamedConstructor = false;
                  };
                  parameterHints.enable = true;
                };
              };
            };
          };
          nixd.enable = true;
          ts_ls.enable = true;
          pylsp.enable = true;
          clangd.enable = true;
        };
      };

      sleuth.enable = true;
    };

    extraPlugins = with pkgs.vimPlugins; [
      tabby-nvim
      hydra-nvim
      multicursors-nvim
      yuck-vim
      # evergarden colorscheme (not in nixpkgs)
      # Replace the hash after first failed build - nix will print the correct one
      (pkgs.vimUtils.buildVimPlugin {
        name = "evergarden";
        nvimSkipModule = [ "evergarden.extras" "minidoc" ];
        src = pkgs.fetchFromGitHub {
          owner = "everviolet";
          repo = "nvim";
          rev = "main";
          hash = "sha256-UEnor+FziURTnBKtDyMJPu3GzkdjEZ7XQyePsCA5HIY=";
        };
      })
    ];
  };
}
