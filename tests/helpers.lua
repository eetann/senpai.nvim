local Helpers = {}

Helpers.expect = vim.deepcopy(MiniTest.expect)

Helpers.new_child_neovim = function()
  local child = MiniTest.new_child_neovim()

  ---@diagnostic disable-next-line: inject-field
  child.setup = function()
    child.restart({ "-u", "scripts/test/minimal_init.lua" })
    child.bo.readonly = false
  end

  ---@diagnostic disable-next-line: inject-field
  child.load = function(config)
    child.lua("require('senpai').setup(...)", { config })
  end

  return child
end

Helpers.get_line = function(child, bufnr, row)
  return child.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
end

Helpers.get_all_line = function(child, bufnr)
  return child.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

return Helpers
