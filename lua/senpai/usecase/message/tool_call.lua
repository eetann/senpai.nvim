local utils = require("senpai.usecase.utils")

local M = {}

---@param chat senpai.IChatWindow
---@param content senpai.chat.message.part.tool_call
local function render_base(chat, content)
  if type(content.toolName) ~= "string" or content.toolName == "" then
    return
  end
  local render_text = "\n\nTool Call: `" .. content.toolName .. "`"
  if type(content.args) == "table" and next(content.args) ~= nil then
    render_text = render_text
      .. "\n  args: `"
      .. vim.inspect(content.args)
      .. "`"
  end
  render_text = render_text .. "\n\n"
  utils.set_text_at_last(chat.log_area.bufnr, render_text)
end

---@param chat senpai.IChatWindow
---@param part senpai.chat.message.part.tool_call
function M.render_from_memory(chat, part)
  render_base(chat, part)
end

---@param chat senpai.IChatWindow
---@param part senpai.data_stream_protocol type = "9"
function M.render_from_response(chat, part)
  local content = part.content
  if type(content) == "string" then
    return
  end
  render_base(chat, content)
end

return M
