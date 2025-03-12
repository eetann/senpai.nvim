local Chat = require("senpai.presentation.chat_buffer")

---@class senpai.ChatBufferManager
---@field current string
---@field chats table<string, senpai.ChatBuffer>
local M = {}
M.__index = M

--- @return senpai.ChatBufferManager
function M.new()
  local self = setmetatable({}, M)
  self.current = nil
  self.chats = {}
  return self
end

--- @param thread_id? string
function M:add(thread_id)
  local chat = Chat.new({ thread_id = thread_id })
  self.chats[chat.thread_id] = chat
  self.current = chat.thread_id
end

--- @param thread_id string
function M:delete(thread_id)
  self.chats[thread_id] = nil
  if self.current == thread_id then
    self.current = next(self.chats)
  end
end

--- @return senpai.ChatBuffer?
function M:get_current_chat()
  if self.current then
    return self.chats[self.current]
  end
  return nil
end

--- @param thread_id string
--- @return senpai.ChatBuffer?
function M:get_chat(thread_id)
  return self.chats[thread_id]
end

return M
