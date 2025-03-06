-- https://github.com/echasnovski/mini.nvim/blob/main/TESTING.md
vim.opt.rtp:append(".")

local minitest_dir = "deps/mini.test"
local is_not_a_directory = vim.fn.isdirectory(minitest_dir) == 0
if is_not_a_directory then
	vim.fn.system({ "mkdir", "-p", minitest_dir })
	vim.fn.system({
		"git",
		"clone",
		"https://github.com/echasnovski/mini.test",
		minitest_dir,
	})
end
local nvim_web_devicons_dir = "deps/nvim-web-devicons"
is_not_a_directory = vim.fn.isdirectory(nvim_web_devicons_dir) == 0
if is_not_a_directory then
	vim.fn.system({ "mkdir", "-p", nvim_web_devicons_dir })
	vim.fn.system({
		"git",
		"clone",
		"https://github.com/nvim-tree/nvim-web-devicons",
		nvim_web_devicons_dir,
	})
end

-- Set up 'mini.test' only when calling headless Neovim (like with `make test`)
if #vim.api.nvim_list_uis() == 0 then
	vim.opt.rtp:append(minitest_dir)
	require("mini.test").setup()
end

vim.opt.rtp:append(nvim_web_devicons_dir)
require("nvim-web-devicons").setup()
