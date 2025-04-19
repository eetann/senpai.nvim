local utils = require("senpai.usecase.utils")
local M = {}

local function get_valid_replace_file_id()
  local id = utils.get_replace_file_id()
  if not id or id == "" then
    return nil
  end
  return id
end

local function get_replace_file_result(chat, id)
  local result = chat.replace_file_results[id]
  if not result then
    vim.notify("[senpai] failed to parse <replace_file>", vim.log.levels.ERROR)
    return nil
  end
  return result
end

local function save_and_restore_cursor(chat)
  local row = vim.fn.line(".", chat.log_area.winid)
  local col = vim.fn.col(".", chat.log_area.winid)
  vim.api.nvim_win_set_cursor(chat.log_area.winid, { row, col - 1 })
end

local function setup_edit_window(path)
  vim.cmd("wincmd h")
  vim.cmd("edit " .. path)
  local original_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local original_win = vim.api.nvim_get_current_win()
  local original_buf = vim.api.nvim_get_current_buf()
  local original_filetype =
    vim.api.nvim_get_option_value("filetype", { buf = original_buf })
  return original_lines, original_win, original_buf, original_filetype
end

local function find_replace_range(result)
  local range = utils.find_text(result.path, table.concat(result.search, "\n"))
  if range.start_line == 0 then
    vim.notify("[senpai]: Could not find code.", vim.log.levels.WARN)
    return nil
  end
  return range
end

local function create_and_replace_buffer(
  original_lines,
  range,
  result,
  id,
  original_filetype,
  original_buf
)
  local buf = vim.api.nvim_create_buf(false, true)
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
  return buf
end

local function setup_diff_windows(original_win, win)
  vim.api.nvim_win_call(win, function()
    vim.cmd("diffthis")
  end)
  vim.api.nvim_win_call(original_win, function()
    vim.cmd("diffthis")
  end)
  vim.api.nvim_set_current_win(original_win)
end

---@param chat senpai.IChatWindow
function M.execute(chat)
  local id = get_valid_replace_file_id()
  if not id then
    return
  end

  local result = get_replace_file_result(chat, id)
  if not result then
    return
  end

  save_and_restore_cursor(chat)
  local original_lines, original_win, original_buf, original_filetype =
    setup_edit_window(result.path)

  local range = find_replace_range(result)
  if not range then
    return
  end

  local buf = create_and_replace_buffer(
    original_lines,
    range,
    result,
    id,
    original_filetype,
    original_buf
  )
  local win =
    vim.api.nvim_open_win(buf, false, { vertical = true, win = original_win })

  setup_diff_windows(original_win, win)
end

return M
