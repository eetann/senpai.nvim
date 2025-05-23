local Chat = require("senpai.presentation.chat.window")

---@class senpai.ChatWindowManager
---@field current string|nil
---@field chats table<string, senpai.ChatWindow>
local M = {}
M.__index = M

M.current = nil
M.chats = {}

---@param args senpai.ChatWindowNewArgs
---@return senpai.ChatWindow?
function M.add(args)
  local chat = Chat.new(args)
  if not chat then
    return
  end
  M.chats[chat.thread_id] = chat
  M.current = chat.thread_id
  return chat
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
---@param chat? senpai.ChatWindow
---@param winid? number
function M.show_current_chat(chat, winid)
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
    chat = M.add({})
    M.show_current_chat(chat)
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
---@return senpai.ChatWindow?
function M.replace_new_thread(args)
  local row, col = 1, 0
  local lines = {}
  local current_win = nil
  local chat = M.get_current_chat()
  if
    chat
    and chat.log_area
    and type(chat.log_area.winid) == "number"
    and vim.api.nvim_win_is_valid(chat.log_area.winid)
  then
    current_win = chat.log_area.winid
    lines = vim.api.nvim_buf_get_lines(chat.input_area.bufnr, 0, -1, false)
    row, col = unpack(vim.api.nvim_win_get_cursor(chat.input_area.winid))
    chat.input_area:hide()
    chat.sticky_popup_manager:close_all_popup()
    chat.log_area.winid = nil
    chat.log_area:hide()
  end
  chat = M.add(args or {})
  M.show_current_chat(chat, current_win)
  if chat then
    vim.api.nvim_buf_set_lines(chat.input_area.bufnr, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(chat.input_area.winid, { row, col })
  end
  return chat
end

return M
