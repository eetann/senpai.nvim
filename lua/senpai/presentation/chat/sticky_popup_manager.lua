local DiffPopup = require("senpai.presentation.chat.diff_popup")

---@class senpai.StickyPopupManager: senpai.IStickyPopupManager
local M = {}
M.__index = M

M.VIRTUAL_BLANK_NS = vim.api.nvim_create_namespace("buffer_w_popup_blank")

--- Safely set the current window and cursor position
---@param winid integer Target window ID
---@param pos? {row: integer, col: integer} Cursor position {row, col} (1-based)
local function safe_set_current_win(winid, pos)
  if winid and vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_set_current_win(winid)
    if pos then
      vim.api.nvim_win_set_cursor(winid, { pos.row, pos.col })
    end
  end
end

---@param winid integer
---@param bufnr integer
---@return senpai.StickyPopupManager
function M.new(winid, bufnr)
  local self = setmetatable({}, M)
  self.winid = winid
  self.bufnr = bufnr
  self.popups = {}
  self.rows = {}
  vim.keymap.set("n", "]]", function()
    self:jump_to_next()
  end, { buffer = bufnr })
  vim.keymap.set("n", "[[", function()
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
    callback = function()
      if vim.api.nvim_get_current_win() == self.winid then
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
      popup:close()
      -- Removal from self.popups is handled by the BufUnload event handler
    end
  end
  pcall(vim.api.nvim_del_augroup_by_id, self.group_id)
  self.group_id = nil
end

function M:set_autocmd_on_win_closed()
  vim.api.nvim_create_autocmd("WinClosed", {
    -- group = self.group_id,
    pattern = tostring(self.winid),
    callback = function()
      self:close_all_popup()
    end,
  })
end

---@param start_row integer
---@param height integer
function M:add_virtual_blank_lines(start_row, height)
  if start_row < 0 then
    return
  end

  local virt_lines = {}
  -- popup height + border + height
  for _ = 1, height + 3 do
    table.insert(virt_lines, { { "", "Normal" } })
  end
  vim.api.nvim_buf_set_extmark(
    self.bufnr,
    M.VIRTUAL_BLANK_NS,
    start_row - 1,
    0,
    {
      virt_lines = virt_lines,
    }
  )
end

---@param opts { row: integer, height: integer, filetype: string|nil }
---@return senpai.DiffPopup
function M:add_float_popup(opts)
  local row = opts.row
  local popup = DiffPopup.new({
    winid = self.winid,
    bufnr = self.bufnr,
    row = row,
    height = opts.height,
    filetype = opts.filetype,
  })
  self:add_virtual_blank_lines(row, opts.height)

  -- popup:on(event.BufUnload, function()
  --   self.popups[row]:close()
  --   self.popups[row] = nil
  -- end, { once = true })
  -- TODO: 設定でキーバインドを変更
  popup:map({
    mode = "n",
    key = "]]",
    handler = function()
      self:jump_to_next()
    end,
    {},
  })
  popup:map({
    mode = "n",
    key = "[[",
    handler = function()
      self:jump_to_prev()
    end,
    {},
  })
  popup.renderer:on_unmount(function()
    if vim.api.nvim_win_is_valid(self.winid) then
      vim.api.nvim_win_close(self.winid, true)
      self:close_all_popup()
    end
  end)

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
  local topline = vim.fn.line("w0", self.winid) - 1 -- 0-indexed
  local win_height = vim.api.nvim_win_get_height(self.winid)

  for original_row, popup in pairs(self.popups) do
    local popup_height = popup:get_height()
    if not popup_height then
      goto continue
    end

    -- Check if the popup should be visible within the current viewport
    local target_screen_row = original_row - topline
    local should_be_visible = target_screen_row >= 1
      and target_screen_row <= (win_height - popup_height + 1)
    -- Hide the popup if it's outside the viewport
    if not should_be_visible then
      popup:hide()
      goto continue
    end
    if not popup:is_visible() then
      popup:show()
      goto continue
    end

    -- show new hight popup
    local new_hight = popup_height
    local win_width = vim.api.nvim_win_get_width(self.winid)
    if popup:is_visible() then
      for _, component in pairs(popup.tabs) do
        ---@diagnostic disable-next-line: undefined-field
        if component:is_focused() and component.winid then
          ---@diagnostic disable-next-line: undefined-field
          new_hight = vim.api.nvim_win_get_height(component.winid) + 3
          break
        end
      end
    end

    if not popup.renderer.layout or not popup.renderer.layout._.mounted then
      popup:mount()
    else
      popup.renderer:redraw()
    end

    if popup_height == new_hight then
      goto continue
    end

    popup:set_size(win_width, new_hight)

    -- update virtual_blank_lines
    local extmarks = vim.api.nvim_buf_get_extmarks(
      self.bufnr,
      M.VIRTUAL_BLANK_NS,
      { original_row - 1, 0 },
      { original_row - 1, 0 },
      {}
    )
    for _, extmark in pairs(extmarks) do
      vim.api.nvim_buf_del_extmark(self.bufnr, M.VIRTUAL_BLANK_NS, extmark[1])
    end
    self:add_virtual_blank_lines(original_row, new_hight - 3)

    ::continue::
  end
  vim.cmd("redraw")
end

---@return boolean
function M:focus_next_popup()
  local current_line = vim.api.nvim_win_get_cursor(self.winid)[1]
  for _, row in ipairs(self.rows) do
    if row > current_line then
      self.popups[row]:focus()
      return true
    end
  end
  return false
end

---@return boolean
function M:focus_prev_popup()
  local current_line = vim.api.nvim_win_get_cursor(self.winid)[1]
  for i = #self.rows, 1, -1 do
    local row = self.rows[i]
    if row < current_line then
      self.popups[row]:focus()
      return true
    end
  end
  return false
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
  if #self.rows == 0 then
    return
  end

  local current_win = vim.api.nvim_get_current_win()
  if current_win == self.winid then
    -- === Currently in the main ===
    self:focus_next_popup()
    return
  end

  -- === Currently in a sticky popup ===
  local current_row_index = self:find_row_index_by_winid()
  if not current_row_index then
    return
  end

  local row_below_popup = self.rows[current_row_index] + 1
  local line_count = vim.api.nvim_buf_line_count(self.bufnr)
  row_below_popup = math.min(row_below_popup, line_count)
  safe_set_current_win(self.winid, { row = row_below_popup, col = 0 })
end

function M:jump_to_prev()
  if #self.rows == 0 then
    return
  end

  local current_win = vim.api.nvim_get_current_win()
  if current_win == self.winid then
    -- === Currently in the main ===
    self:focus_prev_popup()
    return
  end
  -- === Currently in a sticky popup ===
  local current_row_index = self:find_row_index_by_winid()
  if not current_row_index then
    return
  end

  local row_above_popup = self.rows[current_row_index] - 1
  local target_line = math.max(0, row_above_popup)
  safe_set_current_win(self.winid, { row = target_line, col = 0 })
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
-- local popup = manager:add_float_popup({ row = 5, height = 10 })
-- local diff_lines = {}
-- local replace_lines = {}
-- local search_lines = {}
-- for i = 1, popup.renderer:get_size().height do
--   table.insert(diff_lines, string.format("diff Popup %d", i))
--   table.insert(replace_lines, string.format("replace Popup %d", i))
--   table.insert(search_lines, string.format("search Popup %d", i))
-- end
-- popup:set_buffer_content("diff", diff_lines)
-- popup:set_buffer_content("replace", replace_lines)
-- popup:set_buffer_content("search", search_lines)
return M
