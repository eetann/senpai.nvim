local Helpers = dofile("tests/helpers.lua")
local child = Helpers.new_child_neovim()
local expect, eq = Helpers.expect, Helpers.expect.equality

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.load()
      child.lua([[M=require("senpai.usecase.utils")]])
    end,
    post_once = child.stop,
  },
})

T["write_chat works"] = function()
  local buffer = child.api.nvim_get_current_buf()
  local text = "foo\nbar"
  child.lua("M.set_text_at_last(...)", { buffer, text })

  local result = child.api.nvim_buf_get_lines(buffer, 0, -1, true)
  eq(result, vim.split(text, "\n"))
end

T["write_chat multiple"] = function()
  local buffer = child.api.nvim_get_current_buf()
  local text = "foo\nbar"
  child.lua("M.set_text_at_last(...)", { buffer, text })
  text = "buz\npiyo"
  child.lua("M.set_text_at_last(...)", { buffer, text })

  local result = child.api.nvim_buf_get_lines(buffer, 0, -1, true)
  eq(result, { "foo", "barbuz", "piyo" })
end

return T
