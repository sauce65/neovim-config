# Declarative NeoVim configuration as a home-manager module.
{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Disable embedded Python 3 / Ruby providers — none of the Lua plugins
    # below need `:python3`/pynvim or `:ruby`. The parquet autocmd shells out
    # to a separate python3 via extraPackages (independent of this flag).
    withPython3 = false;
    withRuby = false;

    plugins = with pkgs.vimPlugins; [
      nvim-tree-lua
      nvim-web-devicons
      telescope-nvim
      telescope-fzf-native-nvim
      plenary-nvim

      (nvim-treesitter.withPlugins (p: [
        p.nix p.lua p.vim p.vimdoc p.bash
        p.javascript p.typescript p.python
        p.rust p.go p.json p.yaml p.markdown
      ]))

      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      luasnip
      cmp_luasnip
      friendly-snippets

      rustaceanvim
      crates-nvim
      claude-code-nvim

      lualine-nvim
      gitsigns-nvim
      tokyonight-nvim
      comment-nvim
      nvim-autopairs
      indent-blankline-nvim
      which-key-nvim
    ];

    initLua = ''
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.mouse = 'a'
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.hlsearch = false
      vim.opt.wrap = false
      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.expandtab = true
      vim.opt.termguicolors = true
      vim.opt.signcolumn = 'yes'
      vim.opt.updatetime = 300
      vim.opt.clipboard = 'unnamedplus'

      vim.g.mapleader = ' '
      vim.g.maplocalleader = ' '

      require('tokyonight').setup({
        style = 'storm',
        on_highlights = function(hl, c)
          hl.Comment = { fg = "#7a88cf", italic = true }
          hl.LineNr = { fg = "#7a88cf" }
          hl.CursorLineNr = { fg = "#a9b1d6", bold = true }
        end,
      })
      vim.cmd.colorscheme('tokyonight')

      require('nvim-tree').setup({
        view = { width = 30 },
        renderer = { group_empty = true },
        filters = { dotfiles = false },
      })

      local telescope_actions = require('telescope.actions')
      require('telescope').setup({
        defaults = {
          layout_strategy = 'horizontal',
          layout_config = {
            horizontal = { preview_width = 0.55, results_width = 0.45 },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120,
          },
          file_ignore_patterns = {
            "^.git/", "^.cache/", "^.local/share/", "^.nix%-profile/",
            "node_modules/", "target/", "build/", "dist/",
            "%.lock", "%.pyc", "%.class", "%.o", "%.a", "%.out",
            "%.jpg", "%.jpeg", "%.png", "%.gif", "%.webp",
            "%.pdf", "%.zip", "%.tar", "%.gz",
          },
          vimgrep_arguments = {
            'rg', '--color=never', '--no-heading', '--with-filename',
            '--line-number', '--column', '--smart-case', '--hidden',
          },
          mappings = {
            i = {
              ['<C-u>'] = false,
              ['<C-d>'] = false,
              ['<C-j>'] = telescope_actions.move_selection_next,
              ['<C-k>'] = telescope_actions.move_selection_previous,
            },
          },
          path_display = { "truncate" },
          dynamic_preview_title = true,
        },
        pickers = {
          find_files = { hidden = true },
          live_grep = { additional_args = function() return { "--hidden" } end },
        },
      })
      pcall(require('telescope').load_extension, 'fzf')

      -- nvim-treesitter main-branch API: enable highlight/indent per buffer
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          if pcall(vim.treesitter.start, args.buf) then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })

      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      vim.lsp.config('nil_ls', {
        cmd = { 'nil' },
        filetypes = { 'nix' },
        root_markers = { 'flake.nix', '.git' },
        capabilities = capabilities,
      })
      vim.lsp.enable('nil_ls')

      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'Hover documentation' })
      vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = 'Go to implementation' })
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename' })
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code action' })

      local cmp = require('cmp')
      local luasnip = require('luasnip')
      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
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
        sources = cmp.config.sources(
          { { name = 'nvim_lsp' }, { name = 'luasnip' } },
          { { name = 'buffer' },   { name = 'path' } }
        ),
      })

      require('lualine').setup({ options = { theme = 'tokyonight' } })

      require('gitsigns').setup({
        signs = {
          add = { text = '+' },
          change = { text = '~' },
          delete = { text = '_' },
          topdelete = { text = '‾' },
          changedelete = { text = '~' },
        },
      })

      require('Comment').setup()
      require('nvim-autopairs').setup()
      require('ibl').setup({ indent = { char = '│' } })
      require('which-key').setup()

      vim.g.rustaceanvim = { server = { capabilities = capabilities } }
      require('crates').setup({
        lsp = { enabled = true, actions = true, completion = true, hover = true },
      })

      -- Parquet viewer: render via pyarrow on read; buffer is read-only JSON
      vim.api.nvim_create_autocmd('BufReadCmd', {
        pattern = '*.parquet',
        callback = function(args)
          local script = [[
import json, sys, pyarrow.parquet as pq
tbl = pq.read_table(sys.argv[1])
print('Schema:'); print(tbl.schema); print()
print('Rows:', tbl.num_rows); print()
print('Data (first 1000 rows):')
print(json.dumps(tbl.slice(0, 1000).to_pylist(), indent=2, default=str))
]]
          local output = vim.fn.systemlist({ 'python3', '-c', script, args.file })
          vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, output)
          vim.bo[args.buf].filetype = 'json'
          vim.bo[args.buf].buftype = 'nofile'
          vim.bo[args.buf].modifiable = false
          vim.bo[args.buf].readonly = true
        end,
      })

      local keymap = vim.keymap.set
      local tb = require('telescope.builtin')

      keymap('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = 'Toggle file tree' })

      keymap('n', '<leader>ff',  tb.find_files,           { desc = 'Find files' })
      keymap('n', '<leader>fg',  tb.live_grep,            { desc = 'Live grep' })
      keymap('n', '<leader>fw',  tb.grep_string,          { desc = 'Find word under cursor' })
      keymap('n', '<leader>fb',  tb.buffers,              { desc = 'Find buffers' })
      keymap('n', '<leader>fo',  tb.oldfiles,             { desc = 'Recent files' })
      keymap('n', '<leader>fgf', tb.git_files,            { desc = 'Find git files' })
      keymap('n', '<leader>fh',  tb.help_tags,            { desc = 'Help tags' })
      keymap('n', '<leader>fr',  tb.resume,               { desc = 'Resume last search' })
      keymap('n', '<leader>fk',  tb.keymaps,              { desc = 'Find keymaps' })
      keymap('n', '<leader>fc',  tb.commands,             { desc = 'Find commands' })
      keymap('n', '<leader>fC',  tb.colorscheme,          { desc = 'Color schemes' })

      keymap('n', '<leader>lr',  tb.lsp_references,        { desc = 'LSP references' })
      keymap('n', '<leader>ld',  tb.lsp_definitions,       { desc = 'LSP definitions' })
      keymap('n', '<leader>li',  tb.lsp_implementations,   { desc = 'LSP implementations' })
      keymap('n', '<leader>ls',  tb.lsp_document_symbols,  { desc = 'Document symbols' })
      keymap('n', '<leader>lw',  tb.lsp_workspace_symbols, { desc = 'Workspace symbols' })
      keymap('n', '<leader>lD',  tb.diagnostics,           { desc = 'Diagnostics' })

      keymap('n', '<leader>gc',  tb.git_commits,           { desc = 'Git commits' })
      keymap('n', '<leader>gbc', tb.git_bcommits,          { desc = 'Buffer commits' })
      keymap('n', '<leader>gb',  tb.git_branches,          { desc = 'Git branches' })
      keymap('n', '<leader>gs',  tb.git_status,            { desc = 'Git status' })

      keymap('n', '<leader>bn', ':bnext<CR>',     { desc = 'Next buffer' })
      keymap('n', '<leader>bp', ':bprevious<CR>', { desc = 'Previous buffer' })
      keymap('n', '<leader>bd', ':bdelete<CR>',   { desc = 'Delete buffer' })

      keymap('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
      keymap('n', '<C-j>', '<C-w>j', { desc = 'Move to bottom window' })
      keymap('n', '<C-k>', '<C-w>k', { desc = 'Move to top window' })
      keymap('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

      keymap('v', '<', '<gv', { desc = 'Indent left' })
      keymap('v', '>', '>gv', { desc = 'Indent right' })

      local crates = require('crates')
      keymap('n', '<leader>ct', crates.toggle,             { desc = 'Toggle crates info' })
      keymap('n', '<leader>cu', crates.update_crate,       { desc = 'Update crate' })
      keymap('n', '<leader>cU', crates.upgrade_crate,      { desc = 'Upgrade crate' })
      keymap('n', '<leader>cA', crates.upgrade_all_crates, { desc = 'Upgrade all crates' })
    '';

    extraPackages = with pkgs; [
      nil
      rust-analyzer
      lua-language-server
      nixpkgs-fmt
      stylua
      ripgrep
      fd
      (python3.withPackages (ps: [ ps.pyarrow ]))
    ];
  };
}
