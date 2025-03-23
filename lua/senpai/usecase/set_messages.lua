local utils = require("senpai.usecase.utils")
local get_messages = require("senpai.usecase.get_messages")
local UserMessage = require("senpai.usecase.message.user")

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
        M.set_assistant_message(chat, message)
      elseif message.role == "tool" then
        M.set_tool_message(chat, message)
      end
    end
    utils.scroll_when_invisible(chat)
  end)
end

---@param chat senpai.ChatWindow
---@param message senpai.chat.message.assistant
function M.set_assistant_message(chat, message)
  if type(message.content) == "string" then
    utils.set_text_at_last(
      chat.chat_log.bufnr,
      message.content --[[@as string]]
    )
  end
  local content = ""
  for _, part in
    pairs(message.content --[=[@as senpai.chat.message.assistant.part[]]=])
  do
    if part.type == "text" then
      content = content .. "\n" .. part.text
    elseif part.type == "reasoning" then
      content = content .. "\n" .. part.text
    end
  end
  utils.set_text_at_last(chat.chat_log.bufnr, content)
end

---@param chat senpai.ChatWindow
---@param message senpai.chat.message.tool
function M.set_tool_message(chat, message)
  for _, part in
    pairs(message.content --[=[@as senpai.chat.message.part.tool_result[]]=])
  do
    if part.type == "tool-result" then
      utils.process_tool_result(chat, part)
    end
  end
end

return M
