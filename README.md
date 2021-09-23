# bufresize.nvim

https://user-images.githubusercontent.com/38927155/134293002-8b710772-3d7c-49fb-a06e-97f09010c104.mov

bufresize.nvim is a very simple plugin that does one thing, it keeps your buffers width and height in proportion when the terminal window is resized.
For example, if you have two buffers side by side, with the left buffer taking up 70% of the terminal width and the right buffer taking up 30% of the terminal width.
Then if you resized the terminal window, the left buffer and right buffer will still take up 70% and 30% respectively(By default, resizing terminal window does not keep the buffers dimension in proportion).

## Prerequistes

- Neovim 0.5 or higher

## Installing

with [vim-plug](https://github.com/junegunn/vim-plug)

```viml
Plug 'kwkarlwang/bufresize.nvim'
```

with [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    "kwkarlwang/bufresize.nvim",
    config = function()
        require("bufresize").setup()
    end
}
```

## Configuration

bufresize.nvim setup provides two options, `register` and `resize`. `register` and `resize` are tables with two keys, `keys` and `trigger_events`. `keys` is a list of keymappings and `trigger_events` are a list of vim events that will trigger the function.

`register` is use to register the current state of buffer windows in the vim, it records the layout, and dimension of each active buffer.

`resize` is use to apply the registered state to the current state so that the current buffers will have the same proportion as the registered states.

### Example configuration:

```lua
use({
    "kwkarlwang/bufresize.nvim",
    config = function()
        local opts = { noremap=true, silent=true }
        require("bufresize").setup({
            register = {
                keys = {
                    { "n", "<leader>w<", "30<C-w><", opts },
                    { "n", "<leader>w>", "30<C-w>>", opts },
                    { "n", "<leader>w+", "10<C-w>+", opts },
                    { "n", "<leader>w-", "10<C-w>-", opts },
                    { "n", "<leader>w_", "<C-w>_", opts },
                    { "n", "<leader>w=", "<C-w>=", opts },
                    { "n", "<leader>w|", "<C-w>|", opts },
                    { "n", "<leader>wo", "<C-w>|<C-w>_", opts },
                },
                trigger_events = { "BufWinEnter", "WinEnter" },
            },
            resize = {
                keys = {},
                trigger_events = { "VimResized" },
            },
        })
    end,
})
```

In this case, if I were to press `<leader>w<` to resize the buffer window, then the plugin will call `register` and record the state after the buffer is resized.
Suppose I make a new split with `:split`, then the `autocmd` event `WinEnter` will trigger and call `register` to record the current state.

In the example above, only the event `VimResized` will trigger the `resize` function, which take the registered states and apply the proportion of the layout to the current terminal width and height.

### Default configuration:

```lua
use({
    "kwkarlwang/bufresize.nvim",
    config = function()
        local opts = { noremap=true, silent=true }
        require("bufresize").setup({
            register = {
                keys = {
                    { "n", "<C-w><", "<C-w><", opts },
                    { "n", "<C-w>>", "<C-w>>", opts },
                    { "n", "<C-w>+", "<C-w>+", opts },
                    { "n", "<C-w>-", "<C-w>-", opts },
                    { "n", "<C-w>_", "<C-w>_", opts },
                    { "n", "<C-w>=", "<C-w>=", opts },
                    { "n", "<C-w>|", "<C-w>|", opts },
                },
                trigger_events = { "BufWinEnter", "WinEnter" },
            },
            resize = {
                keys = {},
                trigger_events = { "VimResized" },
            },
        })
    end,
})
```

### Alternative configuration:

If you don't want to call the setup function, you can also bind `register` and `resize` as followed.

```lua
use({
    "kwkarlwang/bufresize.nvim",
    config = function()
        local opts = { noremap=true, silent=true }
        vim.api.nvim_set_keymap("n", "<C-w><", "<C-w><<cmd>lua require('bufresize').register()<cr>", opts)
        vim.api.nvim_set_keymap("n", "<C-w>>", "<C-w>><cmd>lua require('bufresize').register()<cr>", opts)
        vim.cmd([[
                augroup Resize
                    autocmd!
                    autocmd VimResized * lua require('bufresize').resize()
                augroup END
                ]])
    end,
})
```
