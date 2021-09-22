local vim = vim
local vim_size = {}
local win_size = {}
local winlayout = nil
local register = function()
	local ui = vim.api.nvim_list_uis()[1]
	vim_size.width = ui.width
	vim_size.height = ui.height
	win_size = {}
	for _, winid in pairs(vim.api.nvim_tabpage_list_wins(0)) do
		win_size[winid] = {
			width = vim.api.nvim_win_get_width(winid),
			height = vim.api.nvim_win_get_height(winid),
		}
	end
	winlayout = vim.fn.winlayout()
end
local function count(layout)
	if layout == nil or layout[1] == "leaf" then
		return 0, 0
	end
	local name, list = layout[1], layout[2]
	local width, height = 0, 0
	if name == "row" then
		width = #list - 1
	else
		height = #list
	end
	for _, elem in pairs(list) do
		local res_width, res_height = count(elem)
		width = width + res_width
		height = height + res_height
	end
	return width, height
end
local function recurse(layout, old_width, old_height, new_width, new_height)
	if layout == nil then
		return
	end
	local name, sublayout = layout[1], layout[2]
	if name == "leaf" then
		local winid = sublayout
		local win_dim = win_size[winid]
		if win_dim ~= nil then
			local width_percent = win_dim.width / old_width
			-- minus one for the status line
			local height_percent = win_dim.height / (old_height - 1)
			-- +0.5 for rounding
			vim.api.nvim_win_set_width(winid, math.floor(width_percent * new_width + 0.5))
			vim.api.nvim_win_set_height(winid, math.floor(height_percent * (new_height - 1) + 0.5))
		end
	else
		if name == "row" then
			old_width = old_width - #sublayout + 1
			new_width = new_width - #sublayout + 1
		else
			old_height = old_height - #sublayout + 1
			new_height = new_height - #sublayout + 1
		end
		for _, elem in pairs(sublayout) do
			recurse(elem, old_width, old_height, new_width, new_height)
		end
	end
end
local apply = function()
	if winlayout == nil then
		vim.fn.wincmd("=")
	else
		local ui = vim.api.nvim_list_uis()[1]
		recurse(winlayout, vim_size.width, vim_size.height - vim.o.cmdheight, ui.width, ui.height - vim.o.cmdheight)
	end
end
local resize = function()
	apply()
	register()
end

local function create_augroup(name, events, func)
	vim.cmd("augroup " .. name)
	vim.cmd("autocmd!")
	vim.cmd("autocmd " .. table.concat(events, ",") .. " * " .. func)
	vim.cmd("augroup END")
end

local function create_keymap(mode, from, to, func, opts)
	vim.api.nvim_set_keymap(mode, from, to .. " " .. func, opts)
end

local setup = function(cfg)
	cfg = cfg or {}
	local opts = { noremap = true, silent = true }
	cfg.register = cfg.register or {}
	cfg.register.trigger_events = cfg.register.trigger_events or { "WinEnter", "BufWinEnter" }
	cfg.register.keys = cfg.register.keys
		or {
			{ "n", "<C-w><", "<C-w><", opts },
			{ "n", "<C-w>>", "<C-w>>", opts },
			{ "n", "<C-w>+", "<C-w>+", opts },
			{ "n", "<C-w>-", "<C-w>-", opts },
			{ "n", "<C-w>_", "<C-w>_", opts },
			{ "n", "<C-w>=", "<C-w>=", opts },
			{ "n", "<C-w>|", "<C-w>|", opts },
		}
	cfg.resize = cfg.resize or {}
	cfg.resize.trigger_events = cfg.resize.trigger_events or { "VimResized" }
	cfg.resize.keys = cfg.resize.keys or {}
	create_augroup("Register", cfg.register.trigger_events, "lua require('bufresize').register()")
	create_augroup("Resize", cfg.resize.trigger_events, "lua require('bufresize').resize()")
	for _, key in pairs(cfg.register.keys) do
		create_keymap(key[1], key[2], key[3], "<cmd>lua require('bufresize').register()<cr>", key[4])
	end
	for _, key in pairs(cfg.resize.keys) do
		create_keymap(key[1], key[2], key[3], "<cmd>lua require('bufresize').resize()<cr>", key[4])
	end
end

return {
	register = register,
	resize = resize,
	setup = setup,
}
