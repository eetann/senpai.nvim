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
vim.opt.conceallevel = 1

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
      {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
          require("nvim-treesitter.configs").setup({
            ensure_installed = {
              "astro",
              "bash",
              "c",
              "cpp",
              "css",
              "go",
              "graphql",
              "html",
              "javascript",
              "json",
              "json5",
              "lua",
              "markdown",
              "php",
              "python",
              "regex",
              "rust",
              "sql",
              "toml",
              "tsx",
              "typescript",
              "vim",
              "vue",
              "yaml",
              "zig",
            },
            sync_install = false,
            auto_install = true,
            ignore_install = {},
            highlight = {
              enable = true,
            },
            indent = {
              enable = true,
            },
            matchup = {
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
    opts = {},
  },
}

vim.opt.clipboard = { "unnamedplus", "unnamed" }
vim.o.loadplugins = true
require("lazy").setup({
  spec = plugins,
  change_detection = { enabled = false },
})
