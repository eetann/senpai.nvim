local utils = require("senpai.usecase.utils")
local get_messages = require("senpai.usecase.get_messages")

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
        M.set_user_message(chat, message)
      elseif message.role == "assistant" then
        M.set_assistant_message(chat, message)
      end
      -- TODO: ここから
    end
  end)
end

---@param chat senpai.ChatWindow
---@param message senpai.chat.message.user
function M.set_user_message(chat, message)
  if type(message.content) == "table" then
    utils.process_user_input(chat, message.content.text)
  else
    utils.process_user_input(chat, message.content)
  end
end

---@param chat senpai.ChatWindow
---@param message senpai.chat.message.assistant
function M.set_assistant_message(chat, message)
  if type(message.content) == "table" then
    utils.set_text_at_last(chat.chat_log.bufnr, message.content.text)
  else
    utils.set_text_at_last(chat.chat_log.bufnr, message.content)
  end
end

return M
