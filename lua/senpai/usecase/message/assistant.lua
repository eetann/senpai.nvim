local utils = require("senpai.usecase.utils")

---@class senpai.message.assistant.replace_file_current: senpai.XML.replace_file
---@field id string
---@field tag? string

---@class senpai.message.assistant
---@field chat senpai.IChatWindow
---@field replace_file_current senpai.message.assistant.replace_file_current
---@field current_content string[]
---@field chunks string
local M = {}
M.__index = M

---@param chat senpai.IChatWindow
---@return senpai.message.assistant
function M.new(chat)
  local self = setmetatable({}, M)
  self.chat = chat
  self.chunks = ""
  self.replace_file_current = {
    id = "",
    path = "",
    search = {},
    replace = {},
    tag = nil,
  }
  self.current_content = {}
  return self
end

---@param text string
function M:render_base(text)
  utils.set_text_at_last(self.chat.chat_log.bufnr, text)
end

---@param chunk string
function M:process_chunk(chunk)
  if not chunk:find("\n") then
    self:render_base(chunk)
    return
  end

  local lines = vim.split(chunk, "\n", { plain = true })
  self:render_base(lines[1])
  self:process_line(lines[1])
  self:render_base("\n")

  local last = #lines
  for i = 2, last - 1 do
    local line = lines[i]
    self:render_base(line)
    self:process_line(line)
    self:render_base("\n")
  end
  self:render_base(lines[last])
  self:process_line(lines[last])
end

---@param line string
function M:process_line(line)
  local lower_line = string.lower(line)
  if self.replace_file_current.id == "" then
    if lower_line:match("<replace_file>") then
      self:process_start_replace_file()
    end
    return
  end

  if lower_line:match("</replace_file>") then
    self:process_end_replace_file()
  elseif lower_line:match("<path>.*</path>") then
    self:process_path_tag(line)
  elseif lower_line:match("<search>") then
    self:process_start_search_tag()
  elseif lower_line:match("</search>") then
    self:process_end_search_tag()
  elseif lower_line:match("<replace>") then
    self:process_start_replace_tag()
  elseif lower_line:match("</replace>") then
    self:process_end_replace_tag()
  elseif self.replace_file_current.tag then
    self:process_content_line(line)
  end
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

function M:process_path_tag(line)
  local path = utils.get_relative_path(line:sub(7, -8))
  self.replace_file_current.path = path
  self.replace_file_current.tag = nil
  self.current_content = {}
  utils.replace_text_at_last(
    self.chat.chat_log.bufnr,
    "\nfilepath: " .. path .. "\n"
  )
end

function M:process_start_search_tag()
  self.replace_file_current.tag = "search"
  self.current_content = {}
  -- TODO: 検索スピナーの開始
end

function M:process_end_search_tag()
  self.replace_file_current.search = self.current_content
  self.replace_file_current.tag = nil
  -- TODO: 検索スピナーの終了
end

function M:process_start_replace_tag()
  self.replace_file_current.tag = "replace"
  self.current_content = {}
  local filetype = vim.filetype.match({
    filename = self.replace_file_current.path,
  }) or ""
  utils.replace_text_at_last(
    self.chat.chat_log.bufnr,
    "\n```" .. filetype .. "\n"
  )
end

function M:process_end_replace_tag()
  self.replace_file_current.replace = self.current_content
  self.replace_file_current.tag = nil
  utils.replace_text_at_last(self.chat.chat_log.bufnr, "\n```" .. "\n")
end

function M:process_content_line(line)
  table.insert(self.current_content, line)
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
