<div align="center">

# My Neovim Configuration

![Neovim](https://img.shields.io/badge/-Neovim-57A143?style=for-the-badge&logo=neovim&logoColor=white)
![Lua](https://img.shields.io/badge/-Lua-2C2D72?style=for-the-badge&logo=lua&logoColor=white)
![LazyVim](https://img.shields.io/badge/-LazyVim-2e7de9?style=for-the-badge&logoColor=white)

My personal Neovim setup based on [LazyVim](https://github.com/LazyVim/LazyVim), customized for robotics research and daily development.

</div>

## Features

- **LazyVim** as the base configuration for fast startup and plugin management
- **LSP** support via `mason.nvim` and `nvim-lspconfig`
- **Treesitter** for syntax highlighting and code understanding
- **LaTeX** editing support for writing papers
- **Smooth scrolling** with `neoscroll`
- **Code folding** with `nvim-ufo`
- **Diagnostics** with `trouble.nvim`
- **Custom keymaps** and options tailored to my workflow

## Structure

```
.
├── init.lua                  # Entry point
├── lua/
│   ├── config/
│   │   ├── autocmds.lua      # Auto commands
│   │   ├── keymaps.lua       # Key bindings
│   │   ├── lazy.lua          # Plugin manager setup
│   │   └── options.lua       # Editor options
│   └── plugins/
│       ├── ColorScheme.lua   # Color scheme config
│       ├── latex.lua         # LaTeX support
│       ├── lualine.lua       # Status line
│       ├── mason.lua         # LSP installer
│       ├── neoscroll.lua     # Smooth scrolling
│       ├── nvim-lspconfig.lua # LSP configuration
│       ├── nvim-treesitter.lua # Syntax highlighting
│       ├── nvim-ufo.lua      # Code folding
│       └── trouble.lua       # Diagnostics viewer
├── .wezterm.lua              # WezTerm terminal config
└── stylua.toml               # Lua formatter config
```

## Requirements

- Neovim >= 0.9.0
- Git
- [Nerd Font](https://www.nerdfonts.com/) (for icons)

## Installation

```bash
# Backup existing config
mv ~/.config/nvim ~/.config/nvim.bak

# Clone this repository
git clone https://github.com/shutouyusei/NvimLazy.git ~/.config/nvim

# Launch Neovim (plugins will be installed automatically)
nvim
```
