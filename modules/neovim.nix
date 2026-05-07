# Declarative NeoVim configuration as a home-manager module.
{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;  # Sets EDITOR and VISUAL to nvim
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Disable embedded Python 3 / Ruby providers — none of the Lua plugins
    # below need `:python3`/pynvim or `:ruby`. The parquet autocmd shells out
    # to a separate python3 via extraPackages (independent of this flag).
    withPython3 = false;
    withRuby = false;

    # Plugin configuration
    plugins = with pkgs.vimPlugins; [
      # Essential plugins for a baseline setup

      # File tree explorer
      nvim-tree-lua
      nvim-web-devicons  # Icons for nvim-tree

      # Fuzzy finder
      telescope-nvim
      telescope-fzf-native-nvim
      plenary-nvim  # Required by telescope

      # Treesitter for better syntax highlighting
      (nvim-treesitter.withPlugins (p: [
        p.nix
        p.lua
        p.vim
        p.vimdoc
        p.bash
        p.javascript
        p.typescript
        p.python
        p.rust
        p.go
        p.json
        p.yaml
        p.markdown
      ]))

      # Autocompletion
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      luasnip
      cmp_luasnip
      friendly-snippets

      # Rust development
      rustaceanvim  # Enhanced rust-analyzer integration
      crates-nvim  # Cargo.toml dependency management

      # AI assistant
      claude-code-nvim  # Claude Code CLI integration

      # Status line
      lualine-nvim

      # Git integration
      gitsigns-nvim

      # Color scheme
      tokyonight-nvim

      # Useful utilities
      comment-nvim  # Easy commenting
      nvim-autopairs  # Auto close brackets
      indent-blankline-nvim  # Show indent lines
      which-key-nvim  # Show keybindings
    ];

    initLua = ''
      -- Basic Settings
      vim.opt.number = true           -- Line numbers
      vim.opt.relativenumber = true   -- Relative line numbers
      vim.opt.mouse = 'a'             -- Enable mouse
      vim.opt.ignorecase = true       -- Case insensitive search
      vim.opt.smartcase = true        -- Unless capital letters used
      vim.opt.hlsearch = false        -- Don't highlight searches
      vim.opt.wrap = false            -- Don't wrap lines
      vim.opt.tabstop = 2             -- 2 spaces for tabs
      vim.opt.shiftwidth = 2          -- 2 spaces for indent
      vim.opt.expandtab = true        -- Use spaces instead of tabs
      vim.opt.termguicolors = true    -- True color support
      vim.opt.signcolumn = 'yes'      -- Always show sign column
      vim.opt.updatetime = 300        -- Faster completion
      vim.opt.clipboard = 'unnamedplus' -- System clipboard

      -- Leader key
      vim.g.mapleader = ' '
      vim.g.maplocalleader = ' '

      -- Color scheme
      require('tokyonight').setup({
        style = 'storm',
        transparent = false,
        on_highlights = function(hl, c)
          hl.Comment = { fg = "#7a88cf", italic = true }
          hl.LineNr = { fg = "#7a88cf" }
          hl.CursorLineNr = { fg = "#a9b1d6", bold = true }
        end,
      })
      vim.cmd[[colorscheme tokyonight]]

      -- Nvim-tree setup
      require('nvim-tree').setup({
        view = {
          width = 30,
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = false,
        },
      })

      -- Telescope setup
      require('telescope').setup({
        defaults = {
          -- Layout and UI
          layout_strategy = 'horizontal',
          layout_config = {
            horizontal = {
              preview_width = 0.55,
              results_width = 0.45,
            },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120,
          },
          -- File ignore patterns
          file_ignore_patterns = {
            "^.git/",
            "^.cache/",
            "^.local/share/",
            "^.nix%-profile/",
            "node_modules/",
            "%.lock",
            "%.pyc",
            "%.class",
            "%.o",
            "%.a",
            "%.out",
            "target/",
            "build/",
            "dist/",
            "%.jpg",
            "%.jpeg",
            "%.png",
            "%.gif",
            "%.webp",
            "%.pdf",
            "%.zip",
            "%.tar",
            "%.gz",
          },
          -- Search behavior
          vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
            '--hidden',  -- Search hidden files
          },
          mappings = {
            i = {
              ['<C-u>'] = false,
              ['<C-d>'] = false,
              ['<C-j>'] = require('telescope.actions').move_selection_next,
              ['<C-k>'] = require('telescope.actions').move_selection_previous,
            },
          },
          -- Performance
          path_display = { "truncate" },
          dynamic_preview_title = true,
        },
        pickers = {
          find_files = {
            hidden = true,  -- Show hidden files
          },
          live_grep = {
            additional_args = function()
              return { "--hidden" }
            end,
          },
        },
      })
      pcall(require('telescope').load_extension, 'fzf')

      -- Treesitter setup
      require('nvim-treesitter.configs').setup({
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
        },
      })

      -- LSP Configuration
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- Nix LSP (nil) - Using new vim.lsp.config API (nvim 0.11+)
      vim.lsp.config('nil_ls', {
        cmd = { 'nil' },
        filetypes = { 'nix' },
        root_markers = { 'flake.nix', '.git' },
        capabilities = capabilities,
      })

      vim.lsp.enable('nil_ls')

      -- Key mappings for LSP
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'Hover documentation' })
      vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = 'Go to implementation' })
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename' })
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code action' })

      -- Completion setup
      local cmp = require('cmp')
      local luasnip = require('luasnip')

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          { name = 'buffer' },
          { name = 'path' },
        }),
      })

      -- Lualine setup
      require('lualine').setup({
        options = {
          theme = 'tokyonight',
        },
      })

      -- Gitsigns setup
      require('gitsigns').setup({
        signs = {
          add = { text = '+' },
          change = { text = '~' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
        },
      })

      -- Comment.nvim setup
      require('Comment').setup()

      -- Autopairs setup
      require('nvim-autopairs').setup()

      -- Indent blankline setup
      require('ibl').setup({
        indent = {
          char = '│',
        },
      })

      -- Which-key setup
      require('which-key').setup()

      -- Rustaceanvim setup (automatically configures rust-analyzer)
      vim.g.rustaceanvim = {
        server = {
          capabilities = capabilities,
        },
      }

      -- Crates.nvim setup (Cargo.toml dependency management)
      require('crates').setup({
        lsp = {
          enabled = true,
          actions = true,
          completion = true,
          hover = true,
        },
      })

      -- Claude Code Nvim setup (automatically syncs files with Claude Code CLI)
      -- No configuration needed - automatically reloads files when Claude Code modifies them

      -- Parquet file viewer setup
      vim.api.nvim_create_autocmd({"BufReadPre", "FileReadPre"}, {
        pattern = "*.parquet",
        callback = function()
          -- Store the original file path
          local parquet_file = vim.fn.expand("<afile>:p")

          -- Set buffer options before reading
          vim.bo.readonly = false
          vim.bo.modifiable = true
          vim.bo.buftype = "nofile"
        end,
      })

      vim.api.nvim_create_autocmd({"BufReadPost", "FileReadPost"}, {
        pattern = "*.parquet",
        callback = function()
          local parquet_file = vim.fn.expand("<afile>:p")

          -- Clear the buffer
          vim.api.nvim_buf_set_lines(0, 0, -1, false, {})

          -- Python command to read parquet and convert to JSON
          local cmd = string.format(
            "python3 -c \"import pyarrow.parquet as pq; import json; " ..
            "tbl = pq.read_table('%s'); " ..
            "print('Schema:'); print(tbl.schema); print('''); " ..
            "print('Rows: ' + str(len(tbl))); print('''); " ..
            "print('Data (first 1000 rows):'); " ..
            "df = tbl.to_pandas().head(1000); " ..
            "print(df.to_json(orient='records', indent=2))\"",
            parquet_file
          )

          -- Execute the command and capture output
          local output = vim.fn.systemlist(cmd)

          -- Set the buffer content
          vim.api.nvim_buf_set_lines(0, 0, -1, false, output)

          -- Set buffer options
          vim.bo.filetype = "json"
          vim.bo.readonly = true
          vim.bo.modifiable = false
          vim.bo.modified = false

          -- Add helpful info to the statusline
          vim.b.parquet_source = parquet_file
        end,
      })

      -- Key Mappings
      local keymap = vim.keymap.set

      -- File tree
      keymap('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = 'Toggle file tree' })

      -- Telescope - File & Code Search
      keymap('n', '<leader>ff', require('telescope.builtin').find_files, { desc = 'Find files' })
      keymap('n', '<leader>fg', require('telescope.builtin').live_grep, { desc = 'Live grep' })
      keymap('n', '<leader>fw', require('telescope.builtin').grep_string, { desc = 'Find word under cursor' })
      keymap('n', '<leader>fb', require('telescope.builtin').buffers, { desc = 'Find buffers' })
      keymap('n', '<leader>fo', require('telescope.builtin').oldfiles, { desc = 'Recent files' })
      keymap('n', '<leader>fgf', require('telescope.builtin').git_files, { desc = 'Find git files' })
      keymap('n', '<leader>fh', require('telescope.builtin').help_tags, { desc = 'Help tags' })
      keymap('n', '<leader>fr', require('telescope.builtin').resume, { desc = 'Resume last search' })

      -- Telescope - LSP Integration
      keymap('n', '<leader>lr', require('telescope.builtin').lsp_references, { desc = 'LSP references' })
      keymap('n', '<leader>ld', require('telescope.builtin').lsp_definitions, { desc = 'LSP definitions' })
      keymap('n', '<leader>li', require('telescope.builtin').lsp_implementations, { desc = 'LSP implementations' })
      keymap('n', '<leader>ls', require('telescope.builtin').lsp_document_symbols, { desc = 'Document symbols' })
      keymap('n', '<leader>lw', require('telescope.builtin').lsp_workspace_symbols, { desc = 'Workspace symbols' })
      keymap('n', '<leader>lD', require('telescope.builtin').diagnostics, { desc = 'Diagnostics' })

      -- Telescope - Git Integration
      keymap('n', '<leader>gc', require('telescope.builtin').git_commits, { desc = 'Git commits' })
      keymap('n', '<leader>gbc', require('telescope.builtin').git_bcommits, { desc = 'Buffer commits' })
      keymap('n', '<leader>gb', require('telescope.builtin').git_branches, { desc = 'Git branches' })
      keymap('n', '<leader>gs', require('telescope.builtin').git_status, { desc = 'Git status' })

      -- Telescope - Utilities
      keymap('n', '<leader>fk', require('telescope.builtin').keymaps, { desc = 'Find keymaps' })
      keymap('n', '<leader>fc', require('telescope.builtin').commands, { desc = 'Find commands' })
      keymap('n', '<leader>fC', require('telescope.builtin').colorscheme, { desc = 'Color schemes' })

      -- Buffer navigation
      keymap('n', '<leader>bn', ':bnext<CR>', { desc = 'Next buffer' })
      keymap('n', '<leader>bp', ':bprevious<CR>', { desc = 'Previous buffer' })
      keymap('n', '<leader>bd', ':bdelete<CR>', { desc = 'Delete buffer' })

      -- Window navigation
      keymap('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
      keymap('n', '<C-j>', '<C-w>j', { desc = 'Move to bottom window' })
      keymap('n', '<C-k>', '<C-w>k', { desc = 'Move to top window' })
      keymap('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

      -- Better indenting
      keymap('v', '<', '<gv', { desc = 'Indent left' })
      keymap('v', '>', '>gv', { desc = 'Indent right' })

      -- Crates.nvim keybindings (for Cargo.toml)
      keymap('n', '<leader>ct', ':lua require("crates").toggle()<CR>', { desc = 'Toggle crates info' })
      keymap('n', '<leader>cu', ':lua require("crates").update_crate()<CR>', { desc = 'Update crate' })
      keymap('n', '<leader>cU', ':lua require("crates").upgrade_crate()<CR>', { desc = 'Upgrade crate' })
      keymap('n', '<leader>cA', ':lua require("crates").upgrade_all_crates()<CR>', { desc = 'Upgrade all crates' })
    '';

    # Extra packages available to NeoVim
    extraPackages = with pkgs; [
      # LSP servers
      nil  # Nix LSP
      rust-analyzer  # Rust LSP
      lua-language-server

      # Formatters
      nixpkgs-fmt
      stylua

      # Other tools
      ripgrep  # For telescope grep
      fd  # For telescope file finding
      gcc  # Required for treesitter

      # Parquet file support
      (python3.withPackages (ps: [ ps.pyarrow ]))
    ];
  };
}
