local utils = require("senpai.usecase.utils")

local M = {}

---@param chat senpai.IChatWindow
---@param part senpai.chat.message.part.tool_result
local function render_base(chat, part)
  local result = part.result
  if result == nil then
    return
  end
  if type(result) == "string" then
    ---@cast result string
    utils.set_text_at_last(chat.log_area.bufnr, result)
    return
  end
  local manager = chat.sticky_popup_manager
  if not manager then
    return
  end

  local last_row = manager.rows[#manager.rows]
  local last_block = manager.popups[last_row]
  if part.toolName == "ReplaceInFile" then
    ---@cast result senpai.chat.message.result.replace_in_file
    ---@cast last_block senpai.IDiffBlock
    last_block:tool_result(result)
    return
  end
end

---@param chat senpai.IChatWindow
---@param part senpai.chat.message.part.tool_result
function M.render_from_memory(chat, part)
  render_base(chat, part)
end

---@param chat senpai.IChatWindow
---@param part senpai.data_stream_protocol type = "a"
function M.render_from_response(chat, part)
  local content = part.content
  if type(content) == "string" then
    utils.set_text_at_last(chat.log_area.bufnr, content .. "\n")
    return
  end
  render_base(chat, content)
end

return M
