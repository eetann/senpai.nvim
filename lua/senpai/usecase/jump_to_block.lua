local M = {}

---@param chat senpai.IChatWindow
function M.next(chat)
  vim.api.nvim_set_current_win(chat.log_area.winid)
  local found_input = vim.fn.search("^<Senpai", "Wn")
  local found_next_popup_row = 0
  local manager = chat.sticky_popup_manager
  if manager then
    found_next_popup_row = manager:find_next_popup_row() or 0
  end

  if
    0 < found_input
    and (found_input < found_next_popup_row or found_next_popup_row == 0)
  then
    -- jump to input
    vim.api.nvim_win_set_cursor(0, { found_input + 2, 0 })
  elseif
    0 < found_next_popup_row
    and (found_next_popup_row < found_input or found_input == 0)
  then
    -- jump to popup
    vim.api.nvim_win_set_cursor(0, { found_next_popup_row + 1, 0 })
  end
end

---@param chat senpai.IChatWindow
function M.previous(chat)
  vim.api.nvim_set_current_win(chat.log_area.winid)
  local row, col = unpack(vim.api.nvim_win_get_cursor(chat.log_area.winid))
  local found_input = row - 2 > 0 and row - 2 or 0
  vim.api.nvim_win_set_cursor(0, { found_input, 0 })

  local found_prev_popup_row = 0
  local manager = chat.sticky_popup_manager
  if manager then
    found_prev_popup_row = manager:find_prev_popup_row() or 0
  end

  found_input = vim.fn.search("^<Senpai", "bWn")

  if
    0 < found_input
    and (found_prev_popup_row < found_input or found_prev_popup_row == 0)
  then
    -- jump to input
    vim.api.nvim_win_set_cursor(0, { found_input + 2, 0 })
  elseif
    0 < found_prev_popup_row
    and (found_input < found_prev_popup_row or found_input == 0)
  then
    -- jump to input
    vim.api.nvim_win_set_cursor(0, { found_prev_popup_row + 1, 0 })
  else
    vim.api.nvim_win_set_cursor(0, { row, col })
  end
end

return M
