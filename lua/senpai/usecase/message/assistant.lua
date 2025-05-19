local utils = require("senpai.usecase.utils")
local ReplaceFileHandler =
  require("senpai.usecase.message.replace_file_handler")
local ExecuteCommandHandler =
  require("senpai.usecase.message.execute_command_handler")

---@class senpai.message.assistant
---@field chat senpai.IChatWindow
---@field current_tag "replace_file"|nil
---@field current_content string
---@field line string
---@field namespace integer
---@field tag_handlers table
local M = {}
M.__index = M

---@param chat senpai.IChatWindow
---@return senpai.message.assistant
function M.new(chat)
  local self = setmetatable({}, M)
  self.chat = chat
  self.current_content = ""
  self.line = ""
  self.namespace = vim.api.nvim_create_namespace("sepnai-chat")
  self.tag_handlers = {
    [ReplaceFileHandler.tag_name] = ReplaceFileHandler.new(self.chat),
    [ExecuteCommandHandler.tag_name] = ExecuteCommandHandler.new(self.chat),
  }
  return self
end

---@param text string
function M:render_base(text)
  utils.set_text_at_last(self.chat.log_area.bufnr, text)
end

---@param text string
function M:process_chunk(text)
  local lines = vim.split(text, "\n", { plain = true })
  local length = #lines
  for i = 1, length do
    local chunk = lines[i]
    self.line = self.line .. chunk
    local is_lastline = i == length
    -- chunk: `foo` newline=0
    -- chunk: `foo\nbar` newline=1,0
    -- chunk: `foo\n\nbar` newline=1,1,0
    if length > 1 and not is_lastline then
      chunk = chunk .. "\n"
    end
    -- 0:"...</path>"
    -- 0:"\n</search>"
    -- ---
    -- 0:"<replace>"
    -- 0:"local utils"
    self:process_line(chunk, is_lastline)
    if not is_lastline then
      self.line = ""
    end
  end
end

---@param chunk string
---@param is_lastline boolean
function M:process_line(chunk, is_lastline)
  local lower_line = string.lower(self.line)

  -- Tag start detection
  if not self.current_tag then
    for tag_name, handler in pairs(self.tag_handlers) do
      if lower_line:match("^<" .. tag_name .. ">$") then
        self.current_tag = tag_name
        handler:start_tag()
        return
      end
    end
    if not self.current_tag then
      self:render_base(chunk)
    end
    return
  end

  local current_tag_hander = self.tag_handlers[self.current_tag]
  if not is_lastline then
    local tag_handlers = current_tag_hander.handlers
    for pattern, handler in pairs(tag_handlers) do
      if lower_line:match("^" .. pattern .. "$") then
        handler(current_tag_hander, chunk, self.line)
        self.line = ""
        return
      end
    end
    if lower_line:match("^" .. self.current_tag .. ">$") then
      current_tag_hander:end_tag()
      self.current_tag = nil
      return
    end
  end
  -- end tag
  for tag_name, handler in pairs(self.tag_handlers) do
    if lower_line:match("^</" .. tag_name .. ">$") then
      handler:end_tag()
      self.current_tag = nil
      return
    end
  end

  if self.current_tag then
    self.tag_handlers[self.current_tag]:content_line(chunk)
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
  self:process_chunk(part.content --[[@as string]])
end

return M
