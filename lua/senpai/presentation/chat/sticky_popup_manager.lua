local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event

---@class senpai.StickyPopupManager
---@field bufnr integer
---@field winid integer
---@field popups table<integer, NuiPopup> # { row: popup }
---@field rows integer[]
---@field group_id integer
local M = {}
M.__index = M

local FLOAT_COL = 0
local FLOAT_WIDTH_MARGIN = 2 + 7 -- border(L/R) + signcolumn
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
  self.bufnr = bufnr
  self.winid = winid
  self.popups = {}
  self.rows = {}
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
      for _, popup in pairs(self.popups) do
        ---@diagnostic disable-next-line: invisible
        if not popup._.mounted then
          goto continue
        end
        ::continue::
      end
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
    ---@diagnostic disable-next-line: invisible
    if popup._.mounted then
      popup:unmount()
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
  -- popup height + border
  for _ = 1, height + 2 do
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

---@param opts { row: integer, height: integer, filetype: string }
---@return NuiPopup
function M:add_float_popup(opts)
  local row = opts.row
  local width = vim.api.nvim_win_get_width(self.winid) - FLOAT_WIDTH_MARGIN
  if width < 5 then
    width = 5
  end
  local popup_buf = vim.api.nvim_create_buf(false, true)
  -- vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, make_float_lines(height))

  local popup = Popup({
    enter = false,
    focusable = true,
    relative = {
      type = "buf",
      -- zero-indexed
      position = {
        row = row - 1,
        col = FLOAT_COL,
      },
    },
    filetype = opts.filetype,
    position = 1,
    size = {
      width = width,
      height = opts.height,
    },
    border = {
      style = "rounded",
    },
    bufnr = popup_buf,
  })
  popup:mount()
  self:add_virtual_blank_lines(row, opts.height)

  popup:on(event.BufUnload, function()
    self.popups[row] = nil
  end, { once = true })
  -- TODO: 設定でキーバインドを変更
  popup:map("n", "<Tab>", function()
    self:jump_to_next()
  end, {})
  popup:map("n", "<S-Tab>", function()
    self:jump_to_prev()
  end, {})
  popup:on(event.WinClosed, function()
    if vim.api.nvim_win_is_valid(self.winid) then
      vim.api.nvim_win_close(self.winid, true)
      self:close_all_popup()
    end
  end, {})

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
  local win_width = vim.api.nvim_win_get_width(self.winid)

  for original_row, popup in pairs(self.popups) do
    ---@diagnostic disable-next-line: invisible
    if not popup._.mounted then
      goto continue
    end
    ---@diagnostic disable-next-line: invisible
    local popup_height = popup._.size.height

    -- Check if the popup should be visible within the current viewport
    local target_screen_row = original_row - topline
    local should_be_visible = target_screen_row >= 1
      and target_screen_row <= (win_height - popup_height + 1)
    if not should_be_visible then
      -- Hide the popup if it's outside the viewport
      popup:hide()
      goto continue
    end

    -- show new hight popup
    local new_hight = popup_height
    if popup.winid and vim.api.nvim_win_is_valid(popup.winid) then
      new_hight = vim.api.nvim_win_get_height(popup.winid)
    end
    popup:update_layout({
      size = {
        width = win_width - FLOAT_WIDTH_MARGIN,
        height = new_hight,
      },
      relative = {
        type = "buf",
        -- zero-indexed
        position = { row = original_row - 1, col = FLOAT_COL },
      },
    })
    -- Ensure it's shown if it was previously hidden
    popup:show()

    ---@diagnostic disable-next-line: invisible
    if popup_height == new_hight then
      goto continue
    end

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
    self:add_virtual_blank_lines(original_row, new_hight)

    ::continue::
  end
  vim.cmd("redraw")
end

---@return boolean
function M:focus_next_popup()
  local current_line = vim.api.nvim_win_get_cursor(self.winid)[1]
  for _, row in ipairs(self.rows) do
    if row > current_line then
      safe_set_current_win(self.popups[row].winid, { row = 1, col = 0 })
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
      safe_set_current_win(self.popups[row].winid, { row = 1, col = 0 })
      return true
    end
  end
  return false
end

--- Find the index of the popup data corresponding to the given window ID
---@param winid integer Window ID to search for
---@return integer? index The index in self.popups, or nil if not found
function M:find_row_index_by_winid(winid)
  for i, row in ipairs(self.rows) do
    if self.popups[row].winid == winid then
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
  local current_row_index = self:find_row_index_by_winid(current_win)
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
  local current_row_index = self:find_row_index_by_winid(current_win)
  if not current_row_index then
    return
  end

  local row_above_popup = self.rows[current_row_index] - 1
  local target_line = math.max(0, row_above_popup)
  safe_set_current_win(self.winid, { row = target_line, col = 0 })
end

return M
