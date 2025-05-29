local utils = require("senpai.usecase.utils")
local ToolCallMessage = require("senpai.usecase.message.tool_call")

---@class senpai.message.assistant
---@field chat senpai.IChatWindow
local M = {}
M.__index = M

---@param chat senpai.IChatWindow
---@return senpai.message.assistant
function M.new(chat)
  local self = setmetatable({}, M)
  self.chat = chat
  return self
end

---@param text string
function M:render_base(text)
  utils.set_text_at_last(self.chat.log_area.bufnr, text)
end

---@param chat senpai.IChatWindow
---@param message senpai.chat.message.assistant
function M:render_from_memory(chat, message)
  local content = message.content
  if type(content) == "string" then
    self:render_base(content)
    return
  end
  ---@cast content senpai.chat.message.assistant.part[]
  local text = ""
  for _, part in pairs(content) do
    if part.type == "text" then
      text = text .. part.text
    elseif part.type == "reasoning" then
      text = text .. "\n" .. part.text
    elseif part.type == "tool-call" then
      self:render_base(text .. "\n")
      text = ""
      ToolCallMessage.render_from_memory(chat, part)
    end
  end
  self:render_base(text)
end

---@param part senpai.data_stream_protocol type = "0"
function M:render_from_response(part)
  self:render_base(part.content --[[@as string]])
end

return M
