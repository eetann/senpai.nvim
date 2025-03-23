local Path = require("plenary.path")

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

---@param buffer number
---@param text string
function M.set_text_at_last(buffer, text)
  local lines = vim.split(text, "\n")
  vim.api.nvim_buf_set_text(buffer, -1, -1, -1, -1, lines)
end

---set winbar
---@param winid number|nil
---@param text string
function M.set_winbar(winid, text)
  if not winid then
    return
  end
  if not vim.api.nvim_win_is_valid(winid) then
    return
  end
  vim.api.nvim_set_option_value(
    "winbar",
    "%#Nomal#%=" .. text .. "%=",
    { win = winid, scope = "local" }
  )
end

---@param chat senpai.ChatWindow
function M.scroll_when_invisible(chat)
  local winid = chat.chat_log.winid
  local last_buffer_line = vim.fn.line("$", winid)
  local last_visible_line = vim.fn.line("w$", winid)
  if last_visible_line < last_buffer_line then
    vim.api.nvim_win_call(chat.chat_log.winid, function()
      vim.cmd("normal! G")
    end)
  end
end

function M.get_relative_path(absolute_path)
  return Path:new({ absolute_path }):make_relative(vim.uv.cwd())
end

-- https://gist.github.com/liukun/f9ce7d6d14fa45fe9b924a3eed5c3d99
local char_to_hex = function(c)
  return string.format("%%%02X", string.byte(c))
end

function M.encode_url(url)
  if url == nil then
    return
  end
  url = url:gsub("\n", "\r\n")
  url = url:gsub("([^%w _%%%-%.~])", char_to_hex)
  url = url:gsub(" ", "+")
  return url
end

return M
