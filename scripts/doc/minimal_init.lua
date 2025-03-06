vim.opt.rtp:append(".")

local minidoc_dir = "deps/mini.test"
local is_not_a_directory = vim.fn.isdirectory(minidoc_dir) == 0
if is_not_a_directory then
	vim.fn.system({ "mkdir", "-p", minidoc_dir })
	vim.fn.system({ "git", "clone", "https://github.com/echasnovski/mini.doc", minidoc_dir })
end

vim.opt.rtp:append(minidoc_dir)

require("mini.doc").setup()
