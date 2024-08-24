# jq.nvim

Use [jq](https://jqlang.github.io/jq/) in Neovim.

## Getting Started

Install [jq](https://jqlang.github.io/jq/) or ensure it is on your `PATH`.

### Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{ 'TravisYeah/jq.nvim' }
```

## Usage

Open a `.json` file in Neovim and try the command 

    :Jq or <leader>jq

Edit the first line to alter the `jq` input. The output will update automatically as you type.

You can also pass a command that will be piped into `jq` as input

    :Jq "xclip -o"

or add it to a keymap

```lua
vim.api.nvim_set_keymap('n', '<leader>jc', '<cmd>Jq "xclip -o"<cr>', { noremap = true })
```

Close the window by running the command `:Jq` again or simply exit the window.

