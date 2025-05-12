local ChatWindowManager = require("senpai.presentation.chat.window_manager")
local M = {}

---@param row integer
---@return {start_line: integer, end_line: integer}|nil
local function get_codeblock_range_at_cursor(row)
  vim.api.nvim_win_set_cursor(0, { row, 0 })

  local parser = vim.treesitter.get_parser(0, "markdown")
  if not parser then
    return nil
  end
  local tree = parser:parse()[1]
  local root = tree:root()

  local node = root:named_descendant_for_range(row, 0, row, 0)
  while node do
    if node:type() == "fenced_code_block" then
      local start_row, _, end_row, _ = node:range()
      return { start_line = start_row, end_line = end_row - 1 }
    end
    node = node:parent()
  end
  return nil
end

---@param tab "diff"|"replace"|"search"
---@param row integer|nil
function M.change_replace_tab(tab, row)
  local chat = ChatWindowManager.get_current_chat()
  if not chat then
    return
  end

  local manager = chat.sticky_popup_manager
  if not manager then
    return
  end

  row = row or manager:find_prev_popup_row()
  if not row then
    return
  end

  local diff_block = manager.popups[row]
  if not diff_block then
    return
  end

  vim.api.nvim_set_current_win(chat.log_area.winid)

  local text = ""
  if tab == "diff" then
    text = "```diff\n" .. diff_block.diff_text
  elseif tab == "replace" then
    text = "```" .. diff_block.filetype .. "\n" .. diff_block.replace_text
  else
    text = "```" .. diff_block.filetype .. "\n" .. diff_block.search_text
  end
  text = text .. "\n```\n"

  local range = get_codeblock_range_at_cursor(row + 1)
  if not range then
    return
  end
  vim.api.nvim_buf_set_text(
    chat.log_area.bufnr,
    range.start_line,
    0,
    range.end_line + 1,
    0,
    vim.split(text, "\n")
  )
end

return M
