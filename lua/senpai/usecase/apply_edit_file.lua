local M = {}

---@param chat senpai.IChatWindow
function M.execute(chat)
  local row = vim.fn.line(".", chat.chat_log.winid)
  local col = vim.fn.col(".", chat.chat_log.winid)
  -- example: <SenpaiEditFile id="toolu_vrtx_01YXj1vvRdFUHhf7Q58VGrJy">
  vim.cmd("?^<SenpaiEditFile.*")
  local tool_call_id =
    vim.fn.getline("."):match('^<SenpaiEditFile.*id="([^"]+)"')
  if not tool_call_id or tool_call_id == "" then
    return
  end
  vim.api.nvim_win_set_cursor(chat.chat_log.winid, { row, col - 1 })
  ---@cast tool_call_id string

  local result = chat.edit_file_results[tool_call_id]
  -- TODO: ここでdiff
  vim.print(result)
end

return M
