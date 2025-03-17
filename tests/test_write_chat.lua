local Helpers = dofile("tests/helpers.lua")
local child = Helpers.new_child_neovim()
local expect, eq = Helpers.expect, Helpers.expect.equality

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.load()
      child.lua([[M=require("senpai.presentation.write_chat")]])
    end,
    post_once = child.stop,
  },
})

T["write_chat works"] = function()
  local winid = child.api.nvim_get_current_win()
  local buffer = child.api.nvim_get_current_buf()
  local text = "foo\nbar"
  child.lua("M.set_plain_text(...)", { winid, buffer, text })

  local result = child.api.nvim_buf_get_lines(buffer, 0, -1, true)
  eq(result, vim.split(text, "\n"))
end

T["write_chat multiple"] = function()
  local winid = child.api.nvim_get_current_win()
  local buffer = child.api.nvim_get_current_buf()
  local text = "foo\nbar"
  child.lua("M.set_plain_text(...)", { winid, buffer, text })
  text = "buz\npiyo"
  child.lua("M.set_plain_text(...)", { winid, buffer, text })

  local result = child.api.nvim_buf_get_lines(buffer, 0, -1, true)
  eq(result, { "foo", "barbuz", "piyo" })
end

return T
