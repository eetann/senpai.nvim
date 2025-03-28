local M = {}

---abort the chat request
---@param chat senpai.IChatWindow
function M.execute(chat)
  if not chat.job then
    return
  end
  chat.job:shutdown(0, "SIGINT")
end

return M
