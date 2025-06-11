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

---@param type senpai.block_type
---@param args any
---@param row? integer
function M:add_block(type, args, row)
  local common_params = {
    winid = self.winid,
    bufnr = self.bufnr,
    row = row,
  }
  local params = vim.tbl_extend("force", common_params, args)

  local popup
  if type == "replace_in_file" then
    popup =
      require("senpai.presentation.chat.replace_in_file_block").new(params)
  elseif type == "execute_command" then
    popup =
      require("senpai.presentation.chat.execute_command_block").new(params)
  elseif type == "ask_followup_question" then
    popup = require("senpai.presentation.chat.ask_followup_question_block").new(
      params
    )
  elseif type == "write_to_file" then
    popup = require("senpai.presentation.chat.write_to_file_block").new(params)
  elseif type == "search_files" then
    popup = require("senpai.presentation.chat.search_files_block").new(params)
  else
    error("Unknown block type: " .. type)
  end

  row = popup.row
  -- Only add virtual blank line for blocks with UI
  if popup:has_ui() then
    self:add_virtual_blank_line(row)
  end

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

  local previous_row_count = 0
  -- Because the order is not guaranteed with self.popups, sel.rows is used.
  for _, original_row in pairs(self.rows) do
    local popup = self.popups[original_row]
    -- Skip UI-less blocks
    if not popup:has_ui() then
      goto continue
    end

    local target_screen_row = original_row - topline + previous_row_count
    if target_screen_row < 0 or split_height <= target_screen_row + 4 then
      popup:hide()
      goto continue
    end

    previous_row_count = previous_row_count + 1
    if not popup:is_visible() then
      popup:show()
      goto continue
    end
    if not popup.renderer.layout or not popup.renderer.layout._.mounted then
      popup:mount()
      goto continue
    end

    local old_width = popup:get_width()
    local new_width = popup.get_adjust_width(self.winid)
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
function M:find_next_popup_row(block_type)
  local current_line = vim.api.nvim_win_get_cursor(self.winid)[1]
  for _, row in ipairs(self.rows) do
    if row < current_line then
      goto continue
    end
    local popup = self.popups[row]
    -- Skip UI-less blocks
    if not popup:has_ui() then
      goto continue
    end
    if not block_type or (block_type and popup.block_type == block_type) then
      return row
    end
    ::continue::
  end
  return nil
end

--- Find the row of the previous popup above the current line
function M:find_prev_popup_row(block_type)
  local current_line = vim.api.nvim_win_get_cursor(self.winid)[1]
  for i = #self.rows, 1, -1 do
    local row = self.rows[i]
    if current_line <= row then
      goto continue
    end
    local popup = self.popups[row]
    -- Skip UI-less blocks
    if not popup:has_ui() then
      goto continue
    end
    if not block_type or (block_type and popup.block_type == block_type) then
      return row
    end
    ::continue::
  end
  return nil
end

--- Find the index of the popup
---@return integer? index The index in self.popups, or nil if not found
function M:find_row_index_by_winid()
  for i, row in ipairs(self.rows) do
    local popup = self.popups[row]
    -- Skip UI-less blocks
    if popup:has_ui() and popup:is_focused() then
      return i
    end
  end
  return nil
end

function M:jump_to_next()
  local next_row = self:find_next_popup_row()
  if next_row then
    local popup = self.popups[next_row]
    -- Only focus if the popup has UI
    if popup:has_ui() then
      popup:focus()
    end
  end
end

function M:jump_to_prev()
  local prev_row = self:find_prev_popup_row()
  if prev_row then
    local popup = self.popups[prev_row]
    -- Only focus if the popup has UI
    if popup:has_ui() then
      popup:focus(true)
    end
  end
end

return M
