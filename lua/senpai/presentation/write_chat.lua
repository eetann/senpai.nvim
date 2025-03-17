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

function M.set_plain_text(winid, buffer, text)
  local position1based = M.get_end_position1based(winid)
  local lines = vim.split(text, "\n")
  M.set_text_1based_position(buffer, position1based, lines)
  return position1based
end

-- TODO:
function M.set_stream_text(winid, buffer, textStream)
  local position = M.get_end_position1based(winid)
  for _, chunk in ipairs(textStream) do
    local lines = vim.split(chunk, "\n")
    M.set_text_1based_position(buffer, position, lines)
    local row_length = #lines
    position.row = position.row + row_length - 1
    if row_length > 1 then
      position.col = 1
    end
    position.col = position.col + string.len(lines[row_length])
  end
  M.set_text_1based_position(buffer, position, { "" })
end

return M
