local utils = require("senpai.usecase.utils")

---@class senpai.XML.replace_file
---@field path string
---@field search string[]
---@field replace string[]

---@class senpai.message.assistant.replace_file_current: senpai.XML.replace_file
---@field id string
---@field tag? string

---@class senpai.message.assistant
---@field chat senpai.IChatWindow
---@field replace_file_current senpai.message.assistant.replace_file_current
---@field replace_file_table table<string, senpai.XML.replace_file>
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
  self.replace_file_table = {}
  return self
end

---@param chunk string
function M:process_chunk(chunk)
  self.chunks = self.chunks .. chunk

  while true do
    local nl_pos = self.chunks:find("\n")
    if not nl_pos then
      break
    end

    local line = self.chunks:sub(1, nl_pos - 1) -- before newline
    self.chunks = self.chunks:sub(nl_pos + 1) -- after newline

    self:process_line(line)
  end
end

---@param line string
function M:process_line(line)
  local lower_line = string.lower(line)
  if self.replace_file_current.id == "" then
    if string.match(lower_line, "<replace_file>") then
      self.replace_file_current = {
        id = utils.create_random_id(12),
        path = "",
        search = {},
        replace = {},
      }
    end
    return
  end
  if string.match(lower_line, "</replace_file>") then
    self.replace_file_table[self.replace_file_current.id] = vim.deepcopy({
      path = self.replace_file_current.path,
      search = self.replace_file_current.search,
      replace = self.replace_file_current.replace,
    })
    self.replace_file_current =
      { id = "", path = "", search = {}, replace = {} }
    self.replace_file_current.tag = nil
  elseif string.match(lower_line, "<path>.*</path>") then
    self.replace_file_current.path = line:sub(7, -8)
    self.replace_file_current.tag = nil
    self.current_content = {}
  elseif string.match(lower_line, "<search>") then
    self.replace_file_current.tag = "search"
    self.current_content = {}
  elseif string.match(lower_line, "<replace>") then
    self.replace_file_current.tag = "replace"
    self.current_content = {}
  elseif string.match(lower_line, "</search>") then
    self.replace_file_current.search = self.current_content
    self.replace_file_current.tag = nil
  elseif string.match(lower_line, "</replace>") then
    self.replace_file_current.replace = self.current_content
    self.replace_file_current.tag = nil
  elseif self.replace_file_current.tag then
    table.insert(self.current_content, line)
  end
end

function M:get_results()
  if self.chunks ~= "" then
    self:process_line(self.chunks)
    self.chunks = ""
  end

  return self.replace_file_table
end

---@param text string
function M:render_base(text)
  self:process_chunk(text)
  utils.set_text_at_last(self.chat.chat_log.bufnr, text)
end

---@param message senpai.chat.message.assistant
function M:render_from_memory(message)
  local content = message.content
  if type(content) == "string" then
    self:render_base(content)
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
  self:render_base(text)
end

---@param part senpai.data_stream_protocol type = "0"
function M:render_from_response(part)
  self:render_base(part.content --[[@as string]])
end

return M
