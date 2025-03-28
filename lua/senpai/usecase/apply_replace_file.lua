local utils = require("senpai.usecase.utils")
local M = {}

---@param chat senpai.IChatWindow
function M.execute(chat)
  local row = vim.fn.line(".", chat.log_area.winid)
  local col = vim.fn.col(".", chat.log_area.winid)
  -- example: <SenpaiReplaceFile id="01YXj1vvRdFUHhf7Q58VGrJy">
  vim.cmd("?^<SenpaiReplaceFile.*")
  local id = vim.fn.getline("."):match('^<SenpaiReplaceFile.*id="([^"]+)"')
  if not id or id == "" then
    return
  end
  vim.api.nvim_win_set_cursor(chat.log_area.winid, { row, col - 1 })
  ---@cast id string

  local result = chat.replace_file_results[id]
  vim.print(result)
  vim.cmd("wincmd h")
  vim.cmd("edit " .. result.path)
  local original_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local original_win = vim.api.nvim_get_current_win()
  local original_buf = vim.api.nvim_get_current_buf()
  local original_filetype =
    vim.api.nvim_get_option_value("filetype", { buf = original_buf })

  local range = utils.get_range_by_search(
    vim.api.nvim_get_current_win(),
    table.concat(result.search, "\n")
  )
  if range.start_line == 0 then
    vim.notify("[senpai]: Could not find code.", vim.log.levels.WARN)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local win =
    vim.api.nvim_open_win(buf, false, { vertical = true, win = original_win })

  vim.api.nvim_buf_set_name(buf, "[senpai] " .. id)
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
    result.replace
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
