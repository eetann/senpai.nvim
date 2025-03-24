local utils = require("senpai.usecase.utils")

local M = {}

---@param bufnr number
---@param text string
local function render_base(bufnr, text)
  utils.set_text_at_last(bufnr, text)
end

---@param chat senpai.IChatWindow
---@param message senpai.chat.message.assistant
function M.render_from_memory(chat, message)
  local content = message.content
  if type(content) == "string" then
    render_base(chat.chat_log.bufnr, content)
    return
  end
  -- content is `senpai.chat.message.assistant.part[]`
  local text = ""
  for _, part in pairs(content) do
    if part.type == "text" then
      text = text .. "\n" .. part.text
    elseif part.type == "reasoning" then
      text = text .. "\n" .. part.text
    end
  end
  render_base(chat.chat_log.bufnr, text)
end

---@param chat senpai.IChatWindow
---@param part senpai.data_stream_protocol type = "0"
function M.render_from_response(chat, part)
  render_base(chat.chat_log.bufnr, part.content --[[@as string]])
end

return M
