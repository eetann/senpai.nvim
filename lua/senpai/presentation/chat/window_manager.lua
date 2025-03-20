local Chat = require("senpai.presentation.chat.window")

---@class senpai.ChatWindowManager
---@field current string|nil
---@field chats table<string, senpai.ChatWindow>
local M = {}
M.__index = M

---@nodoc
---@return senpai.ChatWindowManager
function M.new()
  local self = setmetatable({}, M)
  self.current = nil
  self.chats = {}
  return self
end

---@param args senpai.ChatWindowNewArgs
function M:add(args)
  if self.chats[args.thread_id] then
    self.current = args.thread_id
    return
  end
  local chat = Chat.new(args)
  if not chat then
    return
  end
  self.chats[chat.thread_id] = chat
  self.current = chat.thread_id
end

--- @param thread_id string
function M:delete(thread_id)
  self.chats[thread_id] = nil
  if self.current == thread_id then
    self.current = next(self.chats) or nil
  end
end

--- @return senpai.ChatWindow?
function M:get_current_chat()
  if self.current then
    return self.chats[self.current]
  end
  return nil
end

--- @param thread_id string
--- @return senpai.ChatWindow?
function M:get_chat(thread_id)
  return self.chats[thread_id]
end

--- Show the current chat window
function M:show_current_chat()
  local chat = self:get_current_chat()
  if chat then
    chat:show()
  end
end

--- Hide the current chat window
function M:hide_current_chat()
  local chat = self:get_current_chat()
  if chat then
    chat:hide()
  end
end

--- Toggle the current chat window
function M:toggle_current_chat()
  local chat = self:get_current_chat()
  if chat then
    chat:toggle()
  else
    self:add({})
    self:show_current_chat()
  end
end

--- Close the current chat window and remove from manager
function M:close_current_chat()
  if self.current then
    local chat = self.chats[self.current]
    if chat then
      chat:hide()
    end
  else
    print("No current chat to close")
  end
end

return M
