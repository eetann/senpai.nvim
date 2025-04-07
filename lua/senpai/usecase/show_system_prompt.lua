local content_popup = require("senpai.usecase.popup.content_popup")

local M = {}

---@param chat senpai.IChatWindow
function M.execute(chat)
  local content = chat.system_prompt
  if not content or content == "" then
    content = "*No system prompt*"
  end

  content_popup.execute("System prompt", content)
end

return M
