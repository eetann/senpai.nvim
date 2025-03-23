local utils = require("senpai.usecase.utils")

local M = {}

---@param chat senpai.ChatWindow
---@param result table|string
local function render_base(chat, result)
  if type(result) == "string" then
    utils.set_text_at_last(chat.chat_log.bufnr, result)
    return
  end
  if result.toolName == "EditFile" then
    local render_text = string.format(
      [[
<SenpaiEditFile
  filepath="%s" >
<SenapiSearch>

```%s
%s
```

</SenapiSearch>
<SenapiReplace>

```%s
%s
```

</SenapiReplace>
</SenpaiEditFile>
]],
      utils.getrelative_path(result.filepath),
      result.filetype,
      result.searchType,
      result.filetype,
      result.replaceText
    )
    utils.set_text_at_last(chat.chat_log.bufnr, render_text)
    -- TODO: ここでvirt textなど
  end
end

---@param chat senpai.ChatWindow
---@param part senpai.chat.message.part.tool_result
function M.render_from_memory(chat, part)
  render_base(chat, part.result)
end

---@param chat senpai.ChatWindow
---@param part senpai.data_stream_protocol type = "a"
function M.render_from_response(chat, part)
  local content = part.content
  if type(content) == "string" then
    utils.set_text_at_last(chat.chat_log.bufnr, content .. "\n")
    return
  end
  render_base(chat, content)
end

return M
