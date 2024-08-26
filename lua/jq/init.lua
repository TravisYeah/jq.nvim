local helpers = require("jq.helpers")

local api = vim.api
local buf, win, previous_bufnr, json_input
local defaults = {
	width = 80,
	height = 40,
}
local M = {}

local function jq_run(input_text)
	local handle, err = io.popen(input_text .. " 2>&1", "r")
	if err ~= nil then
		print(err)
		return nil
	end

	if handle == nil then
		print("jq plugin error: handle was nil for jq process")
		return
	end

	local jq_output = handle:read("*a")
	handle:close()
	return jq_output
end

local function get_path_from_previous_bufnr()
	local previous_buf_name = vim.api.nvim_buf_get_name(previous_bufnr)
	local file_path = nil
	if vim.fn.fnamemodify(previous_buf_name, ":e") == "json" then
		file_path = previous_buf_name
	end
	return file_path
end

local function get_input_text(input_line)
	local jq_cmd = "jq " .. "'" .. input_line .. "'"

	if json_input and json_input ~= "" then
		return json_input .. " | " .. jq_cmd
	elseif previous_bufnr then
		local file_path = get_path_from_previous_bufnr()
		if file_path then
			return jq_cmd .. " " .. file_path
		end
	end
end

local function isempty(str)
	return str == nil or str == ""
end

local function on_change(bufnr)
	local input_line = api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
	if isempty(input_line) then
		return
	end

	local input_text = get_input_text(input_line)
	if not input_text then
		api.nvim_buf_set_lines(bufnr, 1, -1, false, vim.split("Error: no json input found", "\n"))
		return
	end
	local jq_output = jq_run(input_text)
	if jq_output == "null\n" or jq_output == nil then
		return
	end

	local jq_err = "jq: error:"
	if string.sub(jq_output, 1, string.len(jq_err)) == jq_err then
		return
	end
	if jq_output then
		api.nvim_buf_set_lines(bufnr, 1, -1, false, vim.split(jq_output, "\n"))
	end
end

local function process_args(args)
	args = args or {}

	local input_str = ""
	for i, arg in ipairs(args) do
		input_str = input_str .. " " .. arg
	end
	input_str = string.sub(input_str, 3, string.len(input_str) - 1)
	json_input = input_str
end

local function create_window(args)
	process_args(args)

	buf = api.nvim_create_buf(false, true)
	local width = defaults.width
	local height = defaults.height
	win = api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor(((vim.o.lines - height) / 2) - 1),
		col = math.floor((vim.o.columns - width) / 2),
	})

	vim.cmd("set nowrap")

	api.nvim_buf_set_lines(buf, 0, 1, false, { "." })
	vim.cmd("startinsert")
	api.nvim_win_set_cursor(win, { 1, 2 })

	vim.api.nvim_create_autocmd("TextChanged", {
		desc = "Jq input change",
		group = vim.api.nvim_create_augroup("jq", { clear = true }),
		callback = function()
			on_change(buf)
		end,
	})

	vim.api.nvim_create_autocmd("TextChangedI", {
		desc = "Jq input change",
		group = vim.api.nvim_create_augroup("jq", { clear = true }),
		callback = function()
			on_change(buf)
		end,
	})

	on_change(buf)
end

local function toggle_window(opts)
	local existing_window = win and api.nvim_win_is_valid(win)
	if existing_window then
		api.nvim_win_close(win, true)
		return
	end

	create_window(opts.fargs)
end

local function on_buf_leave()
	previous_bufnr = vim.fn.bufnr()
end

local function search_previous_window(text)
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_close(win, true)
	vim.cmd("/" .. text)
end

local function search_line()
	local text = vim.api.nvim_get_current_line()
	search_previous_window(text)
end

local function search_selection()
	local text = helpers.get_visual_selection()
	search_previous_window(text)
end

function M.setup(opts)
	opts = opts or {}

	if opts.defaults then
		for k, v in pairs(opts.defaults) do
			defaults[k] = v
		end
	end

	api.nvim_create_user_command("Jq", toggle_window, {})

	api.nvim_set_keymap("n", "<leader>jq", "<cmd>Jq<cr>", { noremap = true })
	vim.keymap.set("n", "<leader>jf", search_line, { noremap = true })
	vim.keymap.set("v", "<leader>jf", search_selection, { noremap = true })

	vim.api.nvim_create_autocmd("BufLeave", {
		desc = "Set previous bufnr",
		group = vim.api.nvim_create_augroup("jq", { clear = true }),
		callback = on_buf_leave,
	})
end

return M
