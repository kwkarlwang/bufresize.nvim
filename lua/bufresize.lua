local keymap_opts = { noremap = true, silent = true }
local default_config = {
	register = {
		trigger_events = { "WinEnter", "BufWinEnter" },
		keys = {
			{ "n", "<C-w><", "<C-w><", keymap_opts },
			{ "n", "<C-w>>", "<C-w>>", keymap_opts },
			{ "n", "<C-w>+", "<C-w>+", keymap_opts },
			{ "n", "<C-w>-", "<C-w>-", keymap_opts },
			{ "n", "<C-w>_", "<C-w>_", keymap_opts },
			{ "n", "<C-w>=", "<C-w>=", keymap_opts },
			{ "n", "<C-w>|", "<C-w>|", keymap_opts },
			{ "", "<LeftRelease>", "<LeftRelease>", keymap_opts },
			{ "i", "<LeftRelease>", "<LeftRelease><C-o>", keymap_opts }
		},
		ignore = { 'NvimTree' },

	},
	resize = {
		trigger_events = { "VimResized" },
		keys = {},
		increment = false,
	}
}

local vim_size = {}
local win_size = {}
local winlayout = {}
local can_register = true

local increment = false

local round_percent = function(percent)
	if increment == false then
		return percent
	end
	percent = percent * 100 / increment
	percent = math.floor(percent + 0.5) * increment / 100
	return percent
end

local block_register = function()
	can_register = false
end
local unblock_register = function()
	can_register = true
end

local tabpage_height = function()
	local tabpage_type = vim.o.showtabline
	if tabpage_type == 0 or tabpage_type == 1 and #vim.api.nvim_list_tabpages() < 2 then
		return 0
	else
		return 1
	end
end

local register = function(opts)

	local ignore_filetypes = opts and opts.ignore or default_config.register.ignore

	if can_register == false then
		return
	end
	local ui = vim.api.nvim_list_uis()[1]
	if ui == nil then
		return
	end
	vim_size.width = ui.width
	vim_size.height = ui.height - tabpage_height()
	win_size = {}
	winlayout = {}
	local tabinfo = vim.fn.gettabinfo()
	for _, tab in pairs(tabinfo) do
		win_size[tab.tabnr] = {}
		for _, winid in pairs(tab.windows) do
			local bufnr = vim.api.nvim_win_get_buf(winid)
			local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
			if ignore_filetypes ~= nil and not vim.tbl_isempty(ignore_filetypes) and not vim.tbl_contains(ignore_filetypes, filetype) then
				goto skip
			end
			win_size[tab.tabnr][winid] = {
				width = vim.api.nvim_win_get_width(winid),
				height = vim.api.nvim_win_get_height(winid),
			}
		end
		winlayout[tab.tabnr] = vim.fn.winlayout(tab.tabnr)
	end
	::skip::
end

local gototab = function(num)
	vim.cmd([[execute "normal! ]] .. tostring(num) .. [[gt"]])
end

local function recurse_open(layout, old_width, old_height, new_width, new_height, tabnr)
	if layout == nil then
		return
	end
	local name, sublayout = layout[1], layout[2]
	if name == "leaf" then
		local winid = sublayout
		local win_dim = win_size[tabnr][winid]
		if win_dim ~= nil then
			local width_percent = round_percent(win_dim.width / old_width)
			-- minus one for the status line
			local height_percent = round_percent(win_dim.height / (old_height - 1))
			-- +0.5 for rounding
			pcall(function()
				vim.api.nvim_win_set_width(winid, math.floor(width_percent * new_width + 0.5))
			end)
			pcall(function()
				vim.api.nvim_win_set_height(winid, math.floor(height_percent * (new_height - 1) + 0.5))
			end)
		end
	else
		local newsublayout = {}
		for id, elem in pairs(sublayout) do
			-- A new window not in the registered layout
			if elem[1] == "leaf" and win_size[tabnr][elem[2]] == nil then
				if name == "row" then
					new_width = new_width - vim.api.nvim_win_get_width(elem[2])
				else
					new_height = new_height - vim.api.nvim_win_get_height(elem[2])
				end
			else
				newsublayout[id] = elem
			end
		end

		if name == "row" then
			old_width = old_width - #newsublayout + 1
			new_width = new_width - #newsublayout + 1
		else
			old_height = old_height - #newsublayout + 1
			new_height = new_height - #newsublayout + 1
		end
		for _, elem in pairs(newsublayout) do
			recurse_open(elem, old_width, old_height, new_width, new_height, tabnr)
		end
	end
end

local apply_open = function()
	local curtabnr = vim.fn.tabpagenr()
	if winlayout[curtabnr] == nil then
		vim.cmd("wincmd =")
	else
		local ui = vim.api.nvim_list_uis()[1]
		local old_width, old_height = vim_size.width, vim_size.height
		local layout = vim.fn.winlayout(curtabnr)
		recurse_open(
			layout,
			old_width,
			old_height - vim.o.cmdheight,
			ui.width,
			ui.height - vim.o.cmdheight - tabpage_height(),
			curtabnr
		)
	end
end

local resize_open = function()
	if vim.fn.mode() == "t" then
		-- have to use this workaround until normal! is supported
		local command = [[<C-\><C-n><cmd>lua require('bufresize').resize_open()<cr>i]]
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(command, true, true, true), "n", true)
	else
		block_register()
		apply_open()
		unblock_register()
		register()
	end
end

local function recurse_close(layout, current_windows, old_width, old_height, new_width, new_height, tabnr)
	if layout == nil then
		return
	end
	local name, sublayout = layout[1], layout[2]
	if name == "leaf" then
		local winid = sublayout
		local win_dim = win_size[tabnr][winid]
		if win_dim ~= nil then
			local width_percent = round_percent(win_dim.width / old_width)
			-- minus one for the status line
			local height_percent = round_percent(win_dim.height / (old_height - 1))
			-- +0.5 for rounding
			pcall(function()
				vim.api.nvim_win_set_width(winid, math.floor(width_percent * new_width + 0.5))
			end)
			pcall(function()
				vim.api.nvim_win_set_height(winid, math.floor(height_percent * (new_height - 1) + 0.5))
			end)
		end
	else
		local newsublayout = {}
		for id, elem in pairs(sublayout) do
			if elem[1] == "leaf" and current_windows[elem[2]] == nil then
				if name == "row" then
					old_width = old_width - win_size[tabnr][elem[2]].width - 1
				else
					old_height = old_height - win_size[tabnr][elem[2]].height - 1
				end
			else
				newsublayout[id] = elem
			end
		end

		if name == "row" then
			old_width = old_width - #newsublayout + 1
			new_width = new_width - #newsublayout + 1
		else
			old_height = old_height - #newsublayout + 1
			new_height = new_height - #newsublayout + 1
		end
		for _, elem in pairs(newsublayout) do
			recurse_close(elem, current_windows, old_width, old_height, new_width, new_height, tabnr)
		end
	end
end

local apply_close = function()
	local curtabnr = vim.fn.tabpagenr()
	if winlayout[curtabnr] == nil then
		vim.cmd("wincmd =")
	else
		local ui = vim.api.nvim_list_uis()[1]
		local old_width, old_height = vim_size.width, vim_size.height
		local current_windows_list = vim.fn.gettabinfo(curtabnr)[1].windows
		local current_windows_set = {}
		for _, winid in pairs(current_windows_list) do
			current_windows_set[winid] = true
		end
		recurse_close(
			winlayout[curtabnr],
			current_windows_set,
			old_width,
			old_height - vim.o.cmdheight,
			ui.width,
			ui.height - vim.o.cmdheight - tabpage_height(),
			curtabnr
		)
	end
end

local resize_close = function()
	if vim.fn.mode() == "t" then
		-- have to use this workaround until normal! is supported
		local command = [[<C-\><C-n><cmd>lua require('bufresize').resize_close()<cr>i]]
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(command, true, true, true), "n", true)
	else
		block_register()
		apply_close()
		unblock_register()
		register()
	end
end

local function recurse(layout, old_width, old_height, new_width, new_height, tabnr)
	if layout == nil then
		return
	end
	local name, sublayout = layout[1], layout[2]
	if name == "leaf" then
		local winid = sublayout
		local win_dim = win_size[tabnr][winid]
		if win_dim ~= nil then
			local width_percent = round_percent(win_dim.width / old_width)
			-- minus one for the status line
			local height_percent = round_percent(win_dim.height / (old_height - 1))
			-- +0.5 for rounding
			pcall(function()
				vim.api.nvim_win_set_width(winid, math.floor(width_percent * new_width + 0.5))
			end)
			pcall(function()
				vim.api.nvim_win_set_height(winid, math.floor(height_percent * (new_height - 1) + 0.5))
			end)
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
			recurse(elem, old_width, old_height, new_width, new_height, tabnr)
		end
	end
end
local apply = function()
	local curtabnr = vim.fn.tabpagenr()
	if winlayout[curtabnr] == nil then
		vim.cmd("wincmd =")
	else
		local ui = vim.api.nvim_list_uis()[1]
		for tabnr, layout in pairs(winlayout) do
			gototab(tabnr)
			local old_width, old_height = vim_size.width, vim_size.height
			recurse(
				layout,
				old_width,
				old_height - vim.o.cmdheight,
				ui.width,
				ui.height - vim.o.cmdheight - tabpage_height(),
				tabnr
			)
		end
		gototab(curtabnr)
	end
end
local resize = function()
	if vim.fn.mode() == "t" then
		-- have to use this workaround until normal! is supported
		local command = [[<C-\><C-n><cmd>lua require('bufresize').resize()<cr>i]]
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(command, true, true, true), "n", true)
	else
		block_register()
		apply()
		unblock_register()
		register()
	end
end
local function create_augroup(name, events, func)
	vim.cmd("augroup " .. name)
	vim.cmd("autocmd!")
	vim.cmd("autocmd " .. table.concat(events, ",") .. " * " .. func)
	vim.cmd("augroup END")
end

local function create_keymap(mode, from, to, func, opts)
	vim.api.nvim_set_keymap(mode, from, to .. func, opts)
end

local function merge_config(opts)
	local merged = vim.tbl_deep_extend("force", {}, default_config, opts or {})
	default_config = merged
	return merged
end

local setup = function(user_opts)
	local cfg = merge_config(user_opts)
	if cfg.resize.increment == false then
		increment = false
	else
		increment = cfg.resize.increment or increment
	end
	if #cfg.register.trigger_events > 0 then
		create_augroup("Register", cfg.register.trigger_events, "lua require('bufresize').register()")
	end
	if #cfg.resize.trigger_events > 0 then
		create_augroup("Resize", cfg.resize.trigger_events, "lua require('bufresize').resize()")
	end
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
	resize_open = resize_open,
	resize_close = resize_close,
	setup = setup,
	block_register = block_register,
	unblock_register = unblock_register,
}
