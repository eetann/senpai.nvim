-- https://github.com/echasnovski/mini.nvim/blob/main/TESTING.md
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

vim.g["denops#debug"] = true
local denops_dir = "deps/denops.vim"
is_not_a_directory = vim.fn.isdirectory(denops_dir) == 0
if is_not_a_directory then
  vim.fn.system({ "mkdir", "-p", denops_dir })
  vim.fn.system({
    "git",
    "clone",
    "https://github.com/vim-denops/denops.vim",
    denops_dir,
  })
end
vim.opt.rtp:append(denops_dir)
-- vim.opt.rtp:append(vim.fn.fnamemodify(denops_dir, ":p"))

-- Set up 'mini.test' only when calling headless Neovim (like with `make test`)
if #vim.api.nvim_list_uis() == 0 then
  vim.opt.rtp:append(minitest_dir)
  require("mini.test").setup()
end

-- vim.opt.rtp:append(".")
