# NeoVim Configuration for NixOS

This directory contains a declarative NeoVim configuration for NixOS using home-manager.

## Structure

```
nvim/
├── default.nix    # Main NeoVim configuration
└── README.md      # This file
```

## What's Included

### Essential Plugins

- **nvim-tree.lua**: File explorer (toggle with `<Space>e`)
- **telescope.nvim**: Fuzzy finder for files, grep, buffers
- **nvim-treesitter**: Advanced syntax highlighting
- **nvim-lspconfig**: LSP client configuration
- **nvim-cmp**: Autocompletion engine
- **lualine.nvim**: Status line
- **gitsigns.nvim**: Git integration
- **tokyonight.nvim**: Color scheme

### LSP Servers

- **nil**: Nix language server
- **lua-language-server**: Lua language server

### Key Bindings

Leader key is `<Space>`

#### File Navigation
- `<Space>e` - Toggle file tree

#### Telescope - File & Code Search
- `<Space>ff` - Find files
- `<Space>fg` - Live grep (search all file contents)
- `<Space>fw` - Find word under cursor
- `<Space>fb` - Find buffers
- `<Space>fo` - Recent files (oldfiles)
- `<Space>fgf` - Find git-tracked files only
- `<Space>fh` - Help tags
- `<Space>fr` - Resume last search

#### Telescope - LSP Integration
- `<Space>lr` - Find all references to symbol
- `<Space>ld` - Find definitions
- `<Space>li` - Find implementations
- `<Space>ls` - Browse document symbols (functions/classes)
- `<Space>lw` - Search workspace symbols
- `<Space>lD` - View all diagnostics (errors/warnings)

#### Telescope - Git Integration
- `<Space>gc` - Browse git commits
- `<Space>gbc` - Browse commits for current file
- `<Space>gb` - Switch git branches
- `<Space>gs` - View git status

#### Telescope - Utilities
- `<Space>fk` - Find keymaps (search all shortcuts)
- `<Space>fc` - Find commands
- `<Space>fC` - Preview color schemes

#### Buffer Management
- `<Space>bn` - Next buffer
- `<Space>bp` - Previous buffer
- `<Space>bd` - Delete buffer

#### Window Navigation
- `<C-h>` - Move to left window
- `<C-j>` - Move to bottom window
- `<C-k>` - Move to top window
- `<C-l>` - Move to right window

#### LSP
- `gd` - Go to definition
- `K` - Hover documentation
- `gi` - Go to implementation
- `<Space>rn` - Rename
- `<Space>ca` - Code action

#### Completion
- `<C-Space>` - Trigger completion
- `<Tab>` - Next completion item
- `<CR>` - Confirm completion
- `<C-e>` - Abort completion

## Telescope Configuration Features

The Telescope setup includes several enhancements:

### Smart Ignore Patterns
Automatically excludes common junk files and directories:
- Version control: `.git/`
- Build artifacts: `target/`, `build/`, `dist/`, `node_modules/`
- Binary files: images, PDFs, archives
- Compiled files: `.pyc`, `.class`, `.o`
- Lock files

### Layout & UI
- Horizontal split with 55% preview, 45% results
- Larger window size (87% width, 80% height)
- Truncated paths for better readability

### Search Behavior
- Includes hidden files in searches
- Smart case sensitivity (case-insensitive unless you type uppercase)
- Uses ripgrep with optimized flags

### Navigation Tips
Once in Telescope:
- `<C-j>` / `<C-k>` - Move through results
- `<Enter>` - Open selected file
- `<Esc>` - Close Telescope
- Type to filter results in real-time

## Best Practices for Adding Plugins

### Method 1: Add to `plugins` list (Recommended)

1. Find the plugin on [NixOS Search](https://search.nixos.org/packages?channel=unstable&query=vimPlugins)
2. Add to the `plugins` list in `default.nix`:

```nix
plugins = with pkgs.vimPlugins; [
  # ... existing plugins
  your-new-plugin
];
```

3. Configure in `extraLuaConfig`:

```nix
extraLuaConfig = ''
  require('your-plugin').setup({
    -- your config here
  })
'';
```

### Method 2: Plugin with custom configuration

For plugins that need special handling:

```nix
plugins = with pkgs.vimPlugins; [
  {
    plugin = your-plugin;
    type = "lua";
    config = ''
      require('your-plugin').setup({
        -- your config here
      })
    '';
  }
];
```

### Method 3: Custom/unreleased plugins

For plugins not in nixpkgs:

```nix
plugins = [
  (pkgs.vimUtils.buildVimPlugin {
    name = "custom-plugin";
    src = pkgs.fetchFromGitHub {
      owner = "username";
      repo = "plugin-repo";
      rev = "commit-hash";
      sha256 = "sha256-hash";
    };
  })
];
```

## Adding Language Servers

1. Add the LSP package to `extraPackages`:

```nix
extraPackages = with pkgs; [
  # ... existing packages
  typescript-language-server
  rust-analyzer
];
```

2. Configure in `extraLuaConfig`:

```nix
extraLuaConfig = ''
  -- ... existing config

  -- TypeScript LSP
  lspconfig.tsserver.setup({
    capabilities = capabilities,
  })

  -- Rust LSP
  lspconfig.rust_analyzer.setup({
    capabilities = capabilities,
  })
'';
```

## Adding Formatters/Linters

Add tools to `extraPackages`:

```nix
extraPackages = with pkgs; [
  # ... existing packages
  prettier
  eslint_d
  black
  rustfmt
];
```

Then configure them using a plugin like `null-ls` or `conform.nvim`.

## Modularizing Configuration

As your config grows, you can split it into multiple files:

```
nvim/
├── default.nix          # Main entry point
├── plugins.nix          # Plugin definitions
├── lsp.nix              # LSP configuration
├── keymaps.nix          # Key mappings
└── settings.nix         # Basic settings
```

Example `default.nix` with modules:

```nix
{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    plugins = import ./plugins.nix { inherit pkgs; };

    extraLuaConfig = ''
      ${builtins.readFile ./settings.lua}
      ${builtins.readFile ./lsp.lua}
      ${builtins.readFile ./keymaps.lua}
    '';

    extraPackages = import ./packages.nix { inherit pkgs; };
  };
}
```

## Hybrid Approach: External Config Files

If you prefer managing configs in separate Lua files:

```nix
programs.neovim = {
  enable = true;
  plugins = [ /* plugins here */ ];
};

# Link custom config files
xdg.configFile."nvim/lua/custom" = {
  source = ./lua;
  recursive = true;
};
```

Then in `extraLuaConfig`:
```lua
require('custom.settings')
require('custom.keymaps')
```

## Applying Changes

After modifying the configuration:

```bash
# For standalone home-manager
home-manager switch --flake .#paul

# For NixOS with integrated home-manager
sudo nixos-rebuild switch --flake .#laptop-clean
```

## Troubleshooting

### Plugin not loading
- Verify plugin name exists in nixpkgs
- Check `nvim-tree-lua` uses dashes, not dots in Nix
- Run `:checkhealth` in NeoVim

### LSP not working
- Verify LSP server is in `extraPackages`
- Check `:LspInfo` in NeoVim
- Ensure `lspconfig.SERVER.setup()` is called

### Treesitter issues
- `gcc` must be in `extraPackages`
- Parsers are defined in the plugin config

## Resources

- [NixOS Wiki: Neovim](https://nixos.wiki/wiki/Neovim)
- [home-manager options](https://nix-community.github.io/home-manager/options.xhtml#opt-programs.neovim.enable)
- [Nix Pills](https://nixos.org/guides/nix-pills/)
- [Awesome Neovim](https://github.com/rockerBOO/awesome-neovim)
