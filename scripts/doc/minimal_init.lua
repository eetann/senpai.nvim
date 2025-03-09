vim.env.LAZY_STDPATH = ".repro"
load(
  vim.fn.system(
    "curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"
  )
)()

local plugins = {
  { "echasnovski/mini.doc", opts = {} },
  {
    dir = vim.uv.cwd(),
    dependencies = {
      "vim-denops/denops.vim",
    },
    opts = {},
  },
}

vim.o.loadplugins = true
require("lazy").setup({
  spec = plugins,
  change_detection = { enabled = false },
})
