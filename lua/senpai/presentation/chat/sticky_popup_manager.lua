local DiffPopup = require("senpai.presentation.chat.diff_popup")
local utils = require("senpai.usecase.utils")

---@class senpai.StickyPopupManager: senpai.IStickyPopupManager
local M = {}
M.__index = M

M.VIRTUAL_BLANK_NS = vim.api.nvim_create_namespace("senpai-virtual_blank_ns")

---@param winid integer
---@param bufnr integer
---@return senpai.StickyPopupManager
function M.new(winid, bufnr)
  local self = setmetatable({}, M)
  self.winid = winid
  self.bufnr = bufnr
  self.popups = {}
  self.rows = {}
  self.group_id =
    vim.api.nvim_create_augroup("senpai-sticky-popup-manager", { clear = true })

  vim.keymap.set("n", "<Tab>", function()
    self:jump_to_next()
  end, { buffer = bufnr })
  vim.keymap.set("n", "<S-Tab>", function()
    self:jump_to_prev()
  end, { buffer = bufnr })
  self:set_autocmd_on_win_scrolled()
  self:set_autocmd_on_win_resized()
  self:set_autocmd_on_win_new()
  self:set_autocmd_on_win_closed()
  return self
end

function M:set_autocmd_on_win_scrolled()
  vim.api.nvim_create_autocmd("WinScrolled", {
    group = self.group_id,
    buffer = self.bufnr,
    callback = function(args)
      local target_winid = tonumber(args.match)
      if target_winid == self.winid then
        self:update_float_position()
      end
    end,
  })
end

function M:set_autocmd_on_win_resized()
  vim.api.nvim_create_autocmd("WinResized", {
    group = self.group_id,
    callback = vim.schedule_wrap(function()
      self:update_float_position()
    end),
  })
end

function M:set_autocmd_on_win_new()
  vim.api.nvim_create_autocmd("WinNew", {
    group = self.group_id,
    callback = vim.schedule_wrap(function(args)
      local new_winid = tonumber(args.match)
      if new_winid and vim.api.nvim_win_is_valid(new_winid) then
        self:update_float_position()
      end
    end),
  })
end

function M:close_all_popup()
  for _, popup in pairs(self.popups) do
    if popup:is_visible() then
      popup:unmount()
    end
  end
  pcall(vim.api.nvim_del_augroup_by_id, self.group_id)
end

function M:set_autocmd_on_win_closed()
  vim.api.nvim_create_autocmd("WinClosed", {
    group = self.group_id,
    pattern = tostring(self.winid),
    callback = function()
      self:close_all_popup()
    end,
  })
end

function M:remount(winid)
  self.winid = winid
  for _, popup in pairs(self.popups) do
    popup:renew(winid)
  end

  self.group_id =
    vim.api.nvim_create_augroup("senpai-sticky-popup-manager", { clear = true })
  self:set_autocmd_on_win_scrolled()
  self:set_autocmd_on_win_resized()
  self:set_autocmd_on_win_new()
  self:set_autocmd_on_win_closed()
  self:update_float_position()
end

---@param start_row integer
function M:add_virtual_blank_line(start_row)
  if start_row <= 0 then
    return
  end

  vim.api.nvim_buf_set_extmark(
    self.bufnr,
    M.VIRTUAL_BLANK_NS,
    start_row - 1,
    0,
    {
      virt_lines = { { { "", "Normal" } } },
    }
  )
end

---@param row integer
---@param path string
---@return senpai.DiffPopup
function M:add_float_popup(row, path)
  local popup = DiffPopup.new({
    winid = self.winid,
    bufnr = self.bufnr,
    row = row,
    path = path,
  })
  self:add_virtual_blank_line(row)

  self.popups[row] = popup
  local rows = {}
  for p_row, _ in pairs(self.popups) do
    table.insert(rows, p_row)
  end
  table.sort(rows)
  self.rows = rows

  return popup
end

function M:update_float_position()
  if not (self.winid and vim.api.nvim_win_is_valid(self.winid)) then
    return
  end
  local topline = vim.fn.line("w0", self.winid)
  local split_height = vim.api.nvim_win_get_height(self.winid)

  for original_row, popup in pairs(self.popups) do
    local target_screen_row = original_row - topline
    if target_screen_row < 0 or split_height < target_screen_row then
      popup:hide()
      goto continue
    end

    if not popup:is_visible() then
      popup:show()
      goto continue
    end
    if not popup.renderer.layout or not popup.renderer.layout._.mounted then
      popup:mount()
      goto continue
    end

    local old_width = popup:get_width()
    local new_width =
      DiffPopup.adjust_width(vim.api.nvim_win_get_width(self.winid))
    if old_width == new_width then
      popup.renderer:redraw()
      goto continue
    end
    popup:set_size(new_width, 1)

    ::continue::
  end
  vim.cmd("redraw")
end

--- Find the row of the next popup below the current line
---@return integer|nil
function M:find_next_popup_row()
  local current_line = vim.api.nvim_win_get_cursor(self.winid)[1]
  for _, row in ipairs(self.rows) do
    if current_line <= row then
      return row
    end
  end
  return nil
end

--- Find the row of the previous popup above the current line
---@return integer|nil
function M:find_prev_popup_row()
  local current_line = vim.api.nvim_win_get_cursor(self.winid)[1]
  for i = #self.rows, 1, -1 do
    local row = self.rows[i]
    if row < current_line then
      return row
    end
  end
  return nil
end

--- Find the index of the popup
---@return integer? index The index in self.popups, or nil if not found
function M:find_row_index_by_winid()
  for i, row in ipairs(self.rows) do
    if self.popups[row]:is_focused() then
      return i
    end
  end
  return nil
end

function M:jump_to_next()
  local next_row = self:find_next_popup_row()
  if next_row then
    self.popups[next_row]:focus()
  end
end

function M:jump_to_prev()
  local prev_row = self:find_prev_popup_row()
  if prev_row then
    self.popups[prev_row]:focus(true)
  end
end

-- local Split = require("nui.split")
-- local split = Split({
--   relative = "editor",
--   position = "right",
--   size = "30%",
-- })
-- split:mount()
-- vim.cmd("wincmd h")
-- local arr = {}
-- for i = 1, 50 do
--   arr[i] = ""
-- end
-- vim.api.nvim_buf_set_lines(split.bufnr, 0, -1, false, arr)
-- local manager = M.new(split.winid, split.bufnr)
-- local popup = manager:add_float_popup(5)
return M
