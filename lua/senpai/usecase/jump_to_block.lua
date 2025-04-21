local M = {}

---@param chat senpai.IChatWindow
function M.next(chat)
  vim.api.nvim_set_current_win(chat.log_area.winid)
  local found = vim.fn.search("^<Senpai", "W")
  if found > 0 then
    vim.api.nvim_win_set_cursor(0, { found + 2, 0 })
  end
end

---@param chat senpai.IChatWindow
function M.previous(chat)
  vim.api.nvim_set_current_win(chat.log_area.winid)
  local row, col = unpack(vim.api.nvim_win_get_cursor(chat.log_area.winid))
  local found = row - 2 > 0 and row - 2 or 0
  vim.api.nvim_win_set_cursor(0, { found, 0 })
  found = vim.fn.search("^<Senpai", "bW")
  if found > 0 then
    vim.api.nvim_win_set_cursor(0, { found + 2, 0 })
  else
    vim.api.nvim_win_set_cursor(0, { row, col })
  end
end

return M
