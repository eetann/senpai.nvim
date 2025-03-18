local M = {}

---@param winid number
---@return { row:number, col:number }
function M.get_end_position1based(winid)
  local row = vim.fn.line("$", winid)
  local col = vim.fn.col({ row, "$" }, winid)
  return { row = row, col = col }
end

function M.set_text_1based_position(buffer, position, lines)
  vim.api.nvim_buf_set_text(
    buffer,
    -- 0-based
    position.row - 1,
    position.col - 1,
    position.row - 1,
    position.col - 1,
    lines
  )
end

function M.set_text_at_last(buffer, text)
  local lines = vim.split(text, "\n")
  vim.api.nvim_buf_set_text(buffer, -1, -1, -1, -1, lines)
end

---set winbar
---@param winid number
---@param text string
function M.set_winbar(winid, text)
  vim.api.nvim_set_option_value(
    "winbar",
    "%#Nomal#%=" .. text .. "%=",
    { win = winid }
  )
end

return M
