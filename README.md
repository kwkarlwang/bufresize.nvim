# bufresize.nvim

## Features

### Resize Terminal Window

https://user-images.githubusercontent.com/38927155/134293002-8b710772-3d7c-49fb-a06e-97f09010c104.mov

bufresize.nvim can keep your buffers width and height in proportion when the terminal window is resized.
For example, if you have two buffers side by side, with the left buffer taking up 70% of the terminal width and the right buffer taking up 30% of the terminal width.
Then if you resized the terminal window, the left buffer and right buffer will still take up 70% and 30% respectively(By default, resizing terminal window does not keep the buffers dimension in proportion).

### Resize After Opening Or Closing Window

In addition, bufresize.nvim also support proportional resize when opening or closing a window.

Normally, if you close window D in the below configuration, the height of window D goes to A and C.

```
Without bufresize
---------------          ---------------
|      |      |          |      |      |
|      |  B   |          |      |  B   |
|  A   |------|          |  A   |------|
|      |  C   |    ->    |      |  C   |
|      |      |          |      |      |
---------------          |      |      |
|      D      |          |      |      |
---------------          ---------------
```

With bufresize.nvim, we can distribute the height proportionally to B and C as shown below

```
With bufresize
---------------          ---------------
|      |      |          |      |      |
|      |  B   |          |      |  B   |
|  A   |------|          |  A   |      |
|      |  C   |    ->    |      |------|
|      |      |          |      |      |
---------------          |      |  C   |
|      D      |          |      |      |
---------------          ---------------
```

The same goes for opening a new window. For example, if you open [toggleterm](https://github.com/akinsho/toggleterm.nvim) in vertical direction (windows D in the below figure), the initial windows will go out of proportion.

```
Without bufresize
---------------         ---------------
|      |      |         |      | |    |
|      |  B   |         |      |B|    |
|  A   |      |         |  A   | |    |
|      |------|   ->    |      |-| D  |
|      |      |         |      | |    |
|      |  C   |         |      |C|    |
|      |      |         |      | |    |
---------------         ---------------
```

With bufresize.nvim, we can resize the windows A, B, and C so that their proportion remains the same after opening toggleterm windows.

```
With bufresize
---------------         ---------------
|      |      |         |    |   |    |
|      |  B   |         |    | B |    |
|  A   |      |         |  A |   |    |
|      |------|   ->    |    |---| D  |
|      |      |         |    |   |    |
|      |  C   |         |    | C |    |
|      |      |         |    |   |    |
---------------         ---------------
```

Video demonstrations are available in this [pull request](https://github.com/kwkarlwang/bufresize.nvim/pull/8#issue-1083932435)

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

This section setup bufresize for resizing terminal window. To setup bufresize for opening and closing window, please see the **Exported Functions** section.

bufresize.nvim setup provides two options, `register` and `resize`. `register` and `resize` are tables with two keys, `keys` and `trigger_events`. `keys` is a list of keymappings and `trigger_events` are a list of vim events that will trigger the function.

`register` is use to register the current state of buffer windows in the vim, it records the layout, and dimension of each active buffer.

`resize` is use to apply the registered state to the current state so that the current buffers will have the same proportion as the registered states.

`resize` also has the key `increment`, which will round the height and width percent of a window to the nearest increment.
For example, with the `increment` set to 5, if the neovim window now takes up 52.3% of the terminal window width, after resizing, the neovim window
width percent will round to the nearest increment, which in this case is 50%.
If the `increment` is set to 2, the neovim window width percent would be round to 52%.
To disable rounding to the nearest increment, set `increment` to `false`.

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
                increment = 5,
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
                    { "", "<LeftRelease>", "<LeftRelease>", opts },
                    { "i", "<LeftRelease>", "<LeftRelease><C-o>", opts },
                },
                trigger_events = { "BufWinEnter", "WinEnter" },
            },
            resize = {
                keys = {},
                trigger_events = { "VimResized" },
                increment = false,
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

## Exported Functions

bufresize export the following functions

1. `register`: record the current windows layout and dimensions. This function is called internally by `resize`, `resize_open`, and `resize_close`
2. `resize`: apply resize using the registered state, then register the state after resizing. Should be use with `VimResized` event
3. `resize_open`: find the newly opened window that is in the current state but not in the registered state, adjust the proportion of registered windows accordingly, then apply resize to the registered windows. Should be use with `block_register` to prevent race condition
4. `resize_close`: find the newly closed window that is not in the registered state but not in the current state, adjust the proportion of registered windows accordingly, then apply resize to the registered windows. Should be use with `block_register` to prevent race condition
5. `setup`: setup the proportional resize functionality for resizing terminal window. Please see **Configuration** section for how to setup
6. `block_register`: prevent `register` from recording the state. This is useful for `resize_open` and `resize_close` if `WinEnter` and `BufWinEnter` is in the `trigger_events` for `register`. If we don't use `block_register`, when opening a new window, `register` might be called before `resize_open`, which will make `resize_open` unable to find the newly opened window
7. `unblock_register`: allow `register` to record the state. This function is called internally by `resize`, `resize_open`, and `resize_close` after applying the resize and before calling `register`

### Configuration for `resize_open` and `resize_close`

My personal usage for `resize_open` and `resize_close` is using with [toggleterm](https://github.com/akinsho/toggleterm.nvim).

Assuming you have the default configuration for `setup`, below is my configuration for toggleterm to not mess up the proportion when toggling.

```lua
opts = { noremap = true, silent = true }
map = vim.api.nvim_set_keymap
ToggleTerm = function(direction)
    local command = "ToggleTerm"
    if direction == "horizontal" then
        command = command .. " direction=horizontal"
    elseif direction == "vertical" then
        command = command .. " direction=vertical"
    end
    if vim.bo.filetype == "toggleterm" then
        require("bufresize").block_register()
        vim.api.nvim_command(command)
        require("bufresize").resize_close()
    else
        require("bufresize").block_register()
        vim.api.nvim_command(command)
        require("bufresize").resize_open()
        cmd([[execute "normal! i"]])
    end
end
map("n", "<C-s>", ":lua ToggleTerm()<cr>", opts)
map("n", "<leader>ot", [[:lua ToggleTerm("horizontal")<cr>]], opts)
map("n", "<leader>ol", [[:lua ToggleTerm("vertical")<cr>]], opts)
map("i", "<C-s>", "<esc>:lua ToggleTerm()<cr>", opts)
map("t", "<C-s>", "<C-\\><C-n>:lua ToggleTerm()<cr>", opts)
```

Here is the configuration for applying `resize_close` for closing windows.

```lua
map(
	"t",
	"<leader>wd",
	"<C-\\><C-n>"
		.. ":lua require('bufresize').block_register()<cr>"
		.. "<C-w>c"
		.. ":lua require('bufresize').resize_close()<cr>",
	opts
)
map(
	"n",
	"<leader>wd",
	":lua require('bufresize').block_register()<cr>" .. "<C-w>c" .. ":lua require('bufresize').resize_close()<cr>",
	opts
)
```
