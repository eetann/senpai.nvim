vim.env.LAZY_STDPATH = ".repro"
load(
  vim.fn.system(
    "curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"
  )
)()

local plugins = {
  { "folke/snacks.nvim", priority = 1000, lazy = false, opts = {} },
  { "echasnovski/mini.test", opts = {} },
  -- {
  --   "folke/tokyonight.nvim",
  --   config = function()
  --     vim.cmd([[colorscheme tokyonight]])
  --   end,
  -- },
  -- {
  --   "EdenEast/nightfox.nvim",
  --   config = function()
  --     vim.cmd([[colorscheme terafox]])
  --   end,
  -- },
  {
    dir = vim.uv.cwd(),
    dependencies = {
      "vim-denops/denops.vim",
    },
    opts = {},
  },
}

vim.opt.clipboard = { "unnamedplus", "unnamed" }
vim.o.loadplugins = true
require("lazy").setup({
  spec = plugins,
  change_detection = { enabled = false },
})
