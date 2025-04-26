local Helpers = {}

Helpers.expect = vim.deepcopy(MiniTest.expect)

---@class NvimChild: MiniTest.child
---@field setup function
---@field load function
local nvimChild = {}
nvimChild.api = vim.api
nvimChild.fn = vim.fn

---@return NvimChild
Helpers.new_child_neovim = function()
  ---@class NvimChild
  local child = MiniTest.new_child_neovim()

  child.setup = function()
    child.restart({ "-u", "scripts/test/minimal_init.lua" })
    child.bo.readonly = false
    -- Don't conceal code blocks on Markdown for screenshot
    -- https://github.com/nvim-treesitter/nvim-treesitter/issues/5751#issuecomment-2311310008
    child.lua("require('vim.treesitter.query').set(...)", {
      "markdown",
      "highlights",
      ";From MDeiml/tree-sitter-markdown\n[(fenced_code_block_delimiter)] @punctuation.delimiter",
    })
  end

  -- don't use it now because it reads in lazy.nvim
  -- child.load = function(config)
  --   child.lua("require('senpai').setup(...)", { config })
  -- end

  return child
end

Helpers.get_line = function(child, bufnr, row)
  return child.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
end

Helpers.get_all_lines = function(child, bufnr)
  return child.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

return Helpers
