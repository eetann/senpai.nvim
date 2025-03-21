local Chat = require("senpai.presentation.chat.window")

---@class senpai.ChatWindowManager
---@field current string|nil
---@field chats table<string, senpai.ChatWindow>
local M = {}
M.__index = M

M.current = nil
M.chats = {}

---@param args senpai.ChatWindowNewArgs
function M.add(args)
  if M.chats[args.thread_id] then
    M.current = args.thread_id
    return
  end
  local chat = Chat.new(args)
  if not chat then
    return
  end
  M.chats[chat.thread_id] = chat
  M.current = chat.thread_id
end

--- @param thread_id string
function M.delete(thread_id)
  M.chats[thread_id] = nil
  if M.current == thread_id then
    M.current = next(M.chats) or nil
  end
end

--- @return senpai.ChatWindow?
function M.get_current_chat()
  if M.current then
    return M.chats[M.current]
  end
  return nil
end

--- @param thread_id string
--- @return senpai.ChatWindow?
function M.get_chat(thread_id)
  return M.chats[thread_id]
end

--- Show the current chat window
---@param winid? number
function M.show_current_chat(winid)
  local chat = M.get_current_chat()
  if chat then
    chat:show(winid)
  end
end

--- Hide the current chat window
function M.hide_current_chat()
  local chat = M.get_current_chat()
  if chat then
    chat:hide()
  end
end

--- Toggle the current chat window
function M.toggle_current_chat()
  local chat = M.get_current_chat()
  if chat then
    chat:toggle()
  else
    M.add({})
    M.show_current_chat()
  end
end

--- Close the current chat window and remove from manager
function M.close_current_chat()
  local chat = M.get_current_chat()
  if chat then
    chat:hide()
  end
end

---@param args? senpai.ChatWindowNewArgs
function M.replace_new_thread(args)
  local current_win = nil
  local chat = M.get_current_chat()
  if chat and vim.api.nvim_win_is_valid(chat.chat_log.winid) then
    current_win = chat.chat_log.winid
    chat.chat_input:hide()
    chat.chat_log.winid = nil
    chat.chat_log:hide()
  end
  M.add(args or {})
  M.show_current_chat(current_win)
end

return M
