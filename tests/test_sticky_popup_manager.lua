local Helpers = dofile("tests/helpers.lua")
local child = Helpers.new_child_neovim()
local expect, eq = Helpers.expect, Helpers.expect.equality

---@param c_child NvimChild
---@return NuiSplit
local function make_split(c_child)
  local split = c_child.lua([[
  local Split = require("nui.split")
  local split = Split({
    relative = "editor",
    position = "right",
    size = "70%",
  })
  split:mount()
  _G.manager = M.new(split.winid, split.bufnr)
  return { bufnr = split.bufnr, winid = split.winid }
  ]])
  local lines = {}
  for i = 1, 100 do
    table.insert(lines, string.format("test line: %d", i))
  end
  c_child.api.nvim_buf_set_lines(split.bufnr, 0, -1, false, lines)
  return split
end

---@param c_child NvimChild
---@param row integer
---@param height integer
---@return NuiPopup
local function make_popup(c_child, row, height)
  local popup = c_child.lua(
    [[
  local popup = _G.manager:add_float_popup(...)
  popup:mount()
  return { bufnr = popup.bufnr, winid = popup.winid }
]],
    { { row = row, height = height } }
  )
  local lines = {}
  for i = 1, height do
    table.insert(lines, string.format("Popup %d", i))
  end
  c_child.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)
  return popup
end

---@param c_child NvimChild
---@param bufnr integer
---@param ns integer
---@param extmark_id integer
---@return table
local function get_virt_lines(c_child, bufnr, ns, extmark_id)
  local extmark = c_child.api.nvim_buf_get_extmark_by_id(
    bufnr,
    ns,
    extmark_id,
    { details = true }
  )
  if 3 < #extmark then
    return {}
  end
  return extmark[3].virt_lines
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.lua(
        [[M = require('senpai.presentation.chat.sticky_popup_manager')]]
      )
    end,
    post_once = child.stop,
  },
})

T["StickyPopupManager"] = MiniTest.new_set()

T["StickyPopupManager"]["created popups"] = function()
  child.o.lines, child.o.columns = 30, 50
  make_split(child)
  local row1, hight1 = 5, 5
  local popup1 = make_popup(child, row1, hight1)
  local row2, hight2 = 12, 3
  local popup2 = make_popup(child, row2, hight2)
  expect.reference_screenshot(child.get_screenshot())
  eq(child.api.nvim_win_get_config(popup1.winid).bufpos, { row1 - 1, 0 })
  eq(child.api.nvim_win_get_config(popup2.winid).bufpos, { row2 - 1, 0 })
end

T["StickyPopupManager"]["virtual line"] = function()
  child.o.lines, child.o.columns = 30, 50
  local split = make_split(child)
  local row1, hight1 = 5, 5
  make_popup(child, row1, hight1)
  local row2, hight2 = 12, 3
  make_popup(child, row2, hight2)
  local extmarks = child.api.nvim_buf_get_extmarks(
    split.bufnr,
    -1,
    { row1 - 1, 0 },
    { row2 - 1, 0 },
    {}
  )
  eq(#extmarks ~= 0, true)
  local ns = child.lua_get([[M.VIRTUAL_BLANK_NS]])
  local count = 0
  for _, extmark in pairs(extmarks) do
    if extmark[2] == row1 - 1 then
      local virt_lines = get_virt_lines(child, split.bufnr, ns, extmark[1])
      eq(#virt_lines, hight1 + 2)
      count = count + 1
    elseif extmark[2] == row2 - 1 then
      local virt_lines = get_virt_lines(child, split.bufnr, ns, extmark[1])
      eq(#virt_lines, hight2 + 2)
      count = count + 1
    end
  end
  eq(count, 2)
end

T["StickyPopupManager"]["map"] = function()
  child.o.lines, child.o.columns = 30, 50
  local split = make_split(child)
  local row1, hight1 = 5, 5
  local popup1 = make_popup(child, row1, hight1)
  local row2, hight2 = 12, 3
  local popup2 = make_popup(child, row2, hight2)
  child.api.nvim_set_current_win(split.winid)
  child.api.nvim_win_set_cursor(split.winid, { 1, 0 })

  -- tab
  child.type_keys("]]")
  eq(child.api.nvim_get_current_win(), popup1.winid)
  child.type_keys("]]")
  eq(child.api.nvim_get_current_win(), split.winid)
  child.type_keys("]]")
  eq(child.api.nvim_get_current_win(), popup2.winid)
  child.type_keys("]]")
  eq(child.api.nvim_get_current_win(), split.winid)
  child.type_keys("]]")
  eq(child.api.nvim_get_current_win(), split.winid)
  -- s-tab
  child.type_keys("[[")
  eq(child.api.nvim_get_current_win(), popup2.winid)
  child.type_keys("[[")
  eq(child.api.nvim_get_current_win(), split.winid)
  child.type_keys("[[")
  eq(child.api.nvim_get_current_win(), popup1.winid)
  child.type_keys("[[")
  eq(child.api.nvim_get_current_win(), split.winid)
  child.type_keys("[[")
  eq(child.api.nvim_get_current_win(), split.winid)
end

T["StickyPopupManager"]["scroll"] = function()
  child.o.lines, child.o.columns = 30, 50
  local split = make_split(child)
  local row1, hight1 = 5, 5
  local popup1 = make_popup(child, row1, hight1)
  local row2, hight2 = 12, 3
  local popup2 = make_popup(child, row2, hight2)
  child.api.nvim_set_current_win(split.winid)
  child.api.nvim_win_set_cursor(split.winid, { 1, 0 })
  local lines = { "fooooooooo" }
  child.api.nvim_buf_set_lines(popup1.bufnr, 0, -1, false, lines)

  -- scroll
  child.type_keys("25G")
  eq(child.api.nvim_win_is_valid(popup1.winid), false)
  eq(child.api.nvim_win_is_valid(popup2.winid), true)

  child.api.nvim_set_current_win(split.winid)
  child.api.nvim_win_set_cursor(split.winid, { 1, 0 })
  child.type_keys("]]")
  eq(child.api.nvim_get_current_buf(), popup1.bufnr)
  eq(child.api.nvim_buf_get_lines(popup1.bufnr, 0, 1, false), lines)
end

T["StickyPopupManager"]["WinClosed"] = function()
  child.o.lines, child.o.columns = 30, 50
  local split = make_split(child)
  local row1, hight1 = 5, 5
  local popup1 = make_popup(child, row1, hight1)
  local row2, hight2 = 12, 3
  local popup2 = make_popup(child, row2, hight2)
  child.api.nvim_set_current_win(split.winid)
  child.api.nvim_win_set_cursor(split.winid, { 1, 0 })

  child.type_keys(":q<CR>")
  eq(child.api.nvim_win_is_valid(split.winid), false)
  eq(child.api.nvim_win_is_valid(popup1.winid), false)
  eq(child.api.nvim_win_is_valid(popup2.winid), false)
end

return T
