local utils = require("senpai.usecase.utils")
local get_messages = require("senpai.usecase.get_messages")
local UserMessage = require("senpai.usecase.message.user")
local AssistantMessage = require("senpai.usecase.message.assistant")
local ToolResultMessage = require("senpai.usecase.message.tool_result")

local M = {}

---Getting the specified thread and restoring it to the chat.
---@param chat senpai.ChatWindow
function M.execute(chat)
  get_messages.execute(chat.thread_id, function(messages)
    if #messages == 0 then
      return
    end
    for _, message in pairs(messages) do
      if message.role == "user" then
        UserMessage.render_from_memory(chat, message)
      elseif message.role == "assistant" then
        AssistantMessage.render_from_memory(chat, message)
      elseif message.role == "tool" then
        M.set_tool_message(chat, message)
      end
    end
    utils.scroll_when_invisible(chat)
  end)
end

---@param chat senpai.ChatWindow
---@param message senpai.chat.message.tool
function M.set_tool_message(chat, message)
  for _, part in
    pairs(message.content --[=[@as senpai.chat.message.part.tool_result[]]=])
  do
    if part.type == "tool-result" then
      ToolResultMessage.render_from_memory(chat, part)
    end
  end
end

return M
