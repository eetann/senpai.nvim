vim.env.LAZY_STDPATH = ".repro"
load(
  vim.fn.system(
    "curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"
  )
)()
vim.filetype.add({
  extension = {
    mdx = "mdx",
  },
})

local plugins = {
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
    build = "bun install",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
          ---@diagnostic disable-next-line: missing-fields
          require("nvim-treesitter.configs").setup({
            ensure_installed = {
              "html",
              "markdown",
            },
            sync_install = false,
            auto_install = true,
            highlight = {
              enable = true,
            },
          })
        end,
      },
    },
    lazy = false,
    keys = {
      { "<space>ss", "<Cmd>Senpai toggleChat<CR>" },
    },
    opts = {
      prompt_launchers = {
        ["test message"] = {
          user = "test message. Hello!",
        },
      },
    },
  },
}

vim.opt.clipboard = { "unnamedplus", "unnamed" }
vim.o.loadplugins = true
require("lazy").setup({
  spec = plugins,
  change_detection = { enabled = false },
})
