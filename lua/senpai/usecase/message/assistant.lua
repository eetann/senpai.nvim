local utils = require("senpai.usecase.utils")

---@class senpai.message.assistant.replace_file_current: senpai.XML.replace_file
---@field id string
---@field tag? string

---@class senpai.message.assistant
---@field chat senpai.IChatWindow
---@field replace_file_current senpai.message.assistant.replace_file_current
---@field current_content string
---@field line string
local M = {}
M.__index = M

---@param chat senpai.IChatWindow
---@return senpai.message.assistant
function M.new(chat)
  local self = setmetatable({}, M)
  self.chat = chat
  self.replace_file_current = {
    id = "",
    path = "",
    search = {},
    replace = {},
    tag = nil,
  }
  self.current_content = ""
  self.line = ""
  return self
end

---@param text string
function M:render_base(text)
  utils.set_text_at_last(self.chat.chat_log.bufnr, text)
end

---@param text string
function M:process_chunk(text)
  local lines = vim.split(text, "\n", { plain = true })
  -- TODO: 描画の分岐
  -- searchタグ中は描画させたくない 引数不要 改行なし
  -- 普通のコンテンツは描画 chunk必要 最終行以外は改行あり
  -- search以外のreplace_file中は置き換えの発生あり line必要 改行制御あり 最終行は不要

  local last = #lines
  for i = 1, last do
    local chunk = lines[i]
    self.line = self.line .. chunk
    if chunk ~= "" and last > 1 then
      chunk = chunk .. "\n"
    end
    local is_need_newline = self:process_line(chunk)
    if i ~= last then
      self.line = ""
    end
  end
end

---@param chunk string
---@return boolean # need newline
function M:process_line(chunk)
  local lower_line = string.lower(self.line)
  if self.replace_file_current.id == "" then
    if lower_line:match("<replace_file>") then
      self:process_start_replace_file()
    else
      self:render_base(chunk)
    end
    return true
  end

  if lower_line:match("</replace_file>") then
    self:process_end_replace_file()
    return true
  end
  if lower_line:match("<path>.*</path>") then
    self:process_path_tag()
    return true
  end
  if lower_line:match("<search>") then
    self:process_start_search_tag()
    return false
  end
  if lower_line:match("</search>") then
    self:process_end_search_tag()
    return false
  end
  if lower_line:match("<replace>") then
    self:process_start_replace_tag()
    return true
  end
  if lower_line:match("</replace>") then
    self:process_end_replace_tag()
    return true
  end
  if self.replace_file_current.tag then
    self:process_content_line(chunk)
    return true
  end
  return true
end

function M:process_start_replace_file()
  local id = utils.create_random_id(12)
  self.replace_file_current = {
    id = id,
    path = "",
    search = {},
    replace = {},
  }
  utils.replace_text_at_last(
    self.chat.chat_log.bufnr,
    '\n<SenpaiReplaceFile id="' .. id .. '">\n\n'
  )
end

function M:process_end_replace_file()
  self.chat.replace_file_results[self.replace_file_current.id] = vim.deepcopy({
    path = self.replace_file_current.path,
    search = self.replace_file_current.search,
    replace = self.replace_file_current.replace,
  })
  self.replace_file_current = { id = "", path = "", search = {}, replace = {} }
  self.replace_file_current.tag = nil
  utils.replace_text_at_last(
    self.chat.chat_log.bufnr,
    "\n</SenpaiReplaceFile>\n"
  )
end

function M:process_path_tag()
  local path = utils.get_relative_path(self.line:sub(7, -8))
  self.replace_file_current.path = path
  self.replace_file_current.tag = nil
  self.current_content = ""
  utils.replace_text_at_last(
    self.chat.chat_log.bufnr,
    "filepath: " .. path .. "\n"
  )
end

function M:process_start_search_tag()
  self.replace_file_current.tag = "search"
  self.current_content = ""
  utils.replace_text_at_last(self.chat.chat_log.bufnr, "")
  -- TODO: 検索スピナーの開始
end

function M:process_end_search_tag()
  self.replace_file_current.search =
    vim.split(self.current_content:gsub("\n$", ""), "\n")
  self.replace_file_current.tag = nil
  utils.replace_text_at_last(self.chat.chat_log.bufnr, "")
  -- TODO: 検索スピナーの終了
end

function M:process_start_replace_tag()
  self.replace_file_current.tag = "replace"
  self.current_content = ""
  local filetype = vim.filetype.match({
    filename = self.replace_file_current.path,
  }) or ""
  utils.replace_text_at_last(
    self.chat.chat_log.bufnr,
    "```" .. filetype .. "\n"
  )
end

function M:process_end_replace_tag()
  self.replace_file_current.replace =
    vim.split(self.current_content:gsub("\n$", ""), "\n")
  self.replace_file_current.tag = nil
  utils.replace_text_at_last(self.chat.chat_log.bufnr, "```" .. "\n")
end

function M:process_content_line(chunk)
  self.current_content = self.current_content .. chunk
  if self.replace_file_current.tag ~= "search" then
    self:render_base(chunk)
  end
end

---@param message senpai.chat.message.assistant
function M:render_from_memory(message)
  local content = message.content
  if type(content) == "string" then
    self:process_chunk(content)
    return
  end
  -- content is `senpai.chat.message.assistant.part[]`
  local text = ""
  for _, part in pairs(content) do
    if part.type == "text" then
      text = text .. "\n" .. part.text
    elseif part.type == "reasoning" then
      text = text .. "\n" .. part.text
    end
  end
  self:process_chunk(text)
end

---@param part senpai.data_stream_protocol type = "0"
function M:render_from_response(part)
  self:render_base(part.content --[[@as string]])
end

return M
