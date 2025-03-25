local utils = require("senpai.usecase.utils")
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
  vim.cmd("wincmd h")
  vim.cmd("edit " .. result.filepath)
  local original_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local original_win = vim.api.nvim_get_current_win()
  local original_buf = vim.api.nvim_get_current_buf()
  local original_filetype =
    vim.api.nvim_get_option_value("filetype", { buf = original_buf })

  local range =
    utils.get_range_by_search(vim.api.nvim_get_current_win(), result.searchText)

  local buf = vim.api.nvim_create_buf(false, true)
  local win =
    vim.api.nvim_open_win(buf, false, { vertical = true, win = original_win })

  vim.api.nvim_buf_set_name(buf, "[senpai] " .. tool_call_id)
  vim.api.nvim_set_option_value(
    "filetype",
    original_filetype,
    { buf = original_buf }
  )
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, original_lines)
  vim.api.nvim_buf_set_lines(
    buf,
    range.start_line - 1,
    range.end_line - 1,
    false,
    vim.split(result.replaceText, "\n")
  )

  vim.api.nvim_win_call(win, function()
    vim.cmd("diffthis")
  end)
  vim.api.nvim_win_call(original_win, function()
    vim.cmd("diffthis")
  end)
  vim.api.nvim_set_current_win(original_win)
end

return M
