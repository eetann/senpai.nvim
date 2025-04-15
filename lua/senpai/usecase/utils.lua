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

---@param buffer number
---@param text string
function M.replace_text_at_last(buffer, text)
  local lines = vim.split(text, "\n")
  vim.api.nvim_buf_set_text(buffer, -1, 0, -1, -1, lines)
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

---@param chat senpai.IChatWindow
function M.scroll_when_invisible(chat)
  local winid = chat.log_area.winid
  local last_buffer_line = vim.fn.line("$", winid)
  local last_visible_line = vim.fn.line("w$", winid)
  if last_visible_line < last_buffer_line then
    vim.api.nvim_win_call(chat.log_area.winid, function()
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

---@return string # id
function M.get_replace_file_id()
  -- example: <SenpaiReplaceFile id="01YXj1vvRdFUHhf7Q58VGrJy">
  vim.cmd("?^<SenpaiReplaceFile.*")
  local id = vim.fn.getline("."):match('^<SenpaiReplaceFile.*id="([^"]+)"')
  if not id then
    return ""
  end
  return id
end

---@param winid number
---@param text string
---@return { start_line:number, end_line:number }
function M.get_range_by_search(winid, text)
  -- Simply `end` is confusing due to the grammar, so `end_line` is used.
  local result = { start_line = 0, end_line = 0 }
  local escaped_text, _ = text:gsub("\n", "\\_.")
  -- TODO: 他にもエスケープが必要かも
  vim.api.nvim_win_call(winid, function()
    result.start_line = vim.fn.search(escaped_text) or 0
  end)
  result.end_line = result.start_line + #vim.split(text, "\n")
  return result
end

-- https://gist.github.com/haggen/2fd643ea9a261fea2094
math.randomseed(os.clock() ^ 5)
local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
function M.create_random_id(length)
  local ret = {}
  local r
  for _ = 1, length do
    r = math.random(1, #charset)
    table.insert(ret, charset:sub(r, r))
  end
  return table.concat(ret)
end

-- https://github.com/neovim/neovim/issues/27265
---@param filepath string
function M.get_filetype(filepath)
  local filetype = vim.filetype.match({
    filename = filepath,
  }) or ""
  if filetype == "" then
    if filepath:find(".ts$") then
      return "typescript"
    end
  end
  return filetype
end

---@param text string
---@return {language:string, filename:string}[]
function M.extract_code_block_headers(text)
  local pattern = "`@([^`]+)`"
  local code_block_headers = {}
  for match in string.gmatch(text, pattern) do
    table.insert(code_block_headers, {
      language = M.get_filetype(match),
      filename = match,
    })
  end

  return code_block_headers
end

return M
