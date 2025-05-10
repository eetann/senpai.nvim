local Helpers = dofile("tests/helpers.lua")
local child = Helpers.new_child_neovim()
local expect, eq = Helpers.expect, Helpers.expect.equality

local sleep = function(ms)
  Helpers.sleep(ms, child)
end

---@param c_child NvimChild
---@return NuiSplit
local function make_split(c_child)
  local split = c_child.lua([[
  local Split = require("nui.split")
  local split = Split({
    relative = "editor",
    position = "right",
    size = "80%",
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
---@return { bufnr: integer }
local function make_popup(c_child, row)
  local popup = c_child.lua(
    [[
  local popup = _G.manager:add_float_popup(...)
  popup:change_tab("diff")
  return {
    bufnr = popup.bufnr
  }
]],
    { row }
  )
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
  child.o.lines, child.o.columns = 30, 60
  local split = make_split(child)
  local row1 = 5
  make_popup(child, row1)
  local row2 = 12
  make_popup(child, row2)
  child.lua("_G.manager:update_float_position()")

  -- for vim.schedule
  sleep(500)
  eq(
    child.lua_get(
      [=[_G.manager.popups[...].renderer.layout._.mounted]=],
      { row1 }
    ),
    true
  )
  expect.reference_screenshot(child.get_screenshot())

  local n_tab_winid =
    child.lua_get([=[_G.manager.popups[...].renderer.layout.winid]=], { row1 })
  eq(type(n_tab_winid), "number")
  local parent_win = child.api.nvim_win_get_config(n_tab_winid)

  eq(parent_win.bufpos, { row1 - 1, 0 })
end

T["StickyPopupManager"]["works multiple popup"] = function()
  child.o.lines, child.o.columns = 30, 60
  make_split(child)
  local row1 = 5
  make_popup(child, row1)
  local row2 = 12
  make_popup(child, row2)
  child.lua("_G.manager:update_float_position()")

  -- for vim.schedule
  sleep(500)
  eq(
    child.lua_get(
      [=[_G.manager.popups[...].renderer.layout._.mounted]=],
      { row2 }
    ),
    true
  )

  local n_tab_winid =
    child.lua_get([=[_G.manager.popups[...].renderer.layout.winid]=], { row2 })
  eq(type(n_tab_winid), "number")
  local parent_win = child.api.nvim_win_get_config(n_tab_winid)

  eq(parent_win.bufpos, { row2 - 1, 0 })
end

T["StickyPopupManager"]["virtual line"] = function()
  child.o.lines, child.o.columns = 30, 50
  local split = make_split(child)
  local row1 = 5
  make_popup(child, row1)
  local row2 = 12
  make_popup(child, row2)
  child.lua("_G.manager:update_float_position()")

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
      eq(#virt_lines, 1)
      count = count + 1
    elseif extmark[2] == row2 - 1 then
      local virt_lines = get_virt_lines(child, split.bufnr, ns, extmark[1])
      eq(#virt_lines, 1)
      count = count + 1
    end
  end
  eq(count, 2)
end

T["StickyPopupManager"]["map"] = function()
  child.o.lines, child.o.columns = 30, 50
  local split = make_split(child)
  local row1 = 5
  local popup1 = make_popup(child, row1)
  local row2 = 12
  local popup2 = make_popup(child, row2)
  child.lua("_G.manager:update_float_position()")

  -- for vim.schedule
  sleep(500)

  child.api.nvim_set_current_win(split.winid)
  child.api.nvim_win_set_cursor(split.winid, { 1, 0 })

  -- tab
  child.type_keys("]]")
  eq(child.api.nvim_get_current_buf() == split.bufnr, false)
  child.type_keys("]]")
  eq(child.api.nvim_get_current_buf(), split.bufnr)
  child.type_keys("]]")
  eq(child.api.nvim_get_current_buf() == split.bufnr, false)
  child.type_keys("]]")
  eq(child.api.nvim_get_current_buf(), split.bufnr)
  child.type_keys("]]")
  eq(child.api.nvim_get_current_buf(), split.bufnr)
  -- s-tab
  child.type_keys("[[")
  eq(child.api.nvim_get_current_buf() == split.bufnr, false)
  child.type_keys("[[")
  eq(child.api.nvim_get_current_buf(), split.bufnr)
  child.type_keys("[[")
  eq(child.api.nvim_get_current_buf() == split.bufnr, false)
  child.type_keys("[[")
  eq(child.api.nvim_get_current_buf(), split.bufnr)
  child.type_keys("[[")
  eq(child.api.nvim_get_current_buf(), split.bufnr)
end

T["StickyPopupManager"]["scroll down"] = function()
  child.o.lines, child.o.columns = 30, 50
  local split = make_split(child)
  local row1 = 5
  make_popup(child, row1)
  local row2 = 25
  make_popup(child, row2)
  local row3 = 35
  make_popup(child, row3)

  child.lua("_G.manager:update_float_position()")
  sleep(500)
  eq(child.lua_get("_G.manager.popups[...].renderer.layout", { row3 }), vim.NIL)

  child.api.nvim_set_current_win(split.winid)
  child.api.nvim_win_set_cursor(split.winid, { 1, 0 })

  -- scroll
  child.type_keys("25Gzz")
  sleep(500)
  expect.reference_screenshot(child.get_screenshot())

  eq(
    child.lua_get("_G.manager.popups[...].renderer.layout.winid", { row1 }),
    vim.NIL
  )
  local popup2_winid =
    child.lua_get("_G.manager.popups[...].renderer.layout.winid", { row2 })
  eq(child.api.nvim_win_is_valid(popup2_winid), true)
  local popup3_winid =
    child.lua_get("_G.manager.popups[...].renderer.layout.winid", { row3 })
  eq(child.api.nvim_win_is_valid(popup3_winid), true)

  child.api.nvim_set_current_win(split.winid)
  child.type_keys("gg")
  child.type_keys("]]")
  local popup1_winid =
    child.lua_get("_G.manager.popups[...].renderer.layout.winid", { row1 })
  eq(child.api.nvim_win_is_valid(popup1_winid), true)
end

T["StickyPopupManager"]["scroll up"] = function()
  child.o.lines, child.o.columns = 30, 50
  local split = make_split(child)
  local row1 = 5
  make_popup(child, row1)

  local row2 = 40
  make_popup(child, row2)
  child.lua("_G.manager:update_float_position()")
  sleep(500)
  eq(child.lua_get("_G.manager.popups[...].renderer.layout", { row2 }), vim.NIL)

  child.api.nvim_set_current_win(split.winid)
  child.api.nvim_win_set_cursor(split.winid, { 1, 0 })

  -- scroll
  child.type_keys("45G")
  sleep(500)
  eq(
    child.lua_get("_G.manager.popups[...].renderer.layout.winid", { row1 }),
    vim.NIL
  )
  local popup2_winid =
    child.lua_get("_G.manager.popups[...].renderer.layout.winid", { row2 })
  eq(child.api.nvim_win_is_valid(popup2_winid), true)
end

T["StickyPopupManager"]["WinClosed"] = function()
  child.o.lines, child.o.columns = 30, 50
  local split = make_split(child)
  local row1 = 5
  make_popup(child, row1)
  local row2 = 12
  make_popup(child, row2)
  child.lua("_G.manager:update_float_position()")
  child.api.nvim_set_current_win(split.winid)
  child.api.nvim_win_set_cursor(split.winid, { 1, 0 })

  child.type_keys(":q<CR>")
  eq(child.api.nvim_win_is_valid(split.winid), false)
  eq(child.lua_get([=[_G.manager.popups[5].renderer.layout.winid]=]), vim.NIL)
  eq(child.lua_get([=[_G.manager.popups[12].renderer.layout.winid]=]), vim.NIL)
end

T["StickyPopupManager"]["WinResized"] = function()
  child.o.lines, child.o.columns = 30, 50
  local split = make_split(child)
  local row1 = 5
  make_popup(child, row1)
  local row2 = 12
  make_popup(child, row2)
  child.lua("_G.manager:update_float_position()")
  child.api.nvim_set_current_win(split.winid)
  child.api.nvim_win_set_cursor(split.winid, { 1, 0 })

  child.cmd(":vertical resize +5<CR>")

  sleep(500)
  local FLOAT_WIDTH_MARGIN = 2 + 7
  eq(
    child.lua_get("_G.manager.popups[...].renderer:get_size().width", { row2 }),
    child.api.nvim_win_get_width(0) - FLOAT_WIDTH_MARGIN
  )
end

return T
