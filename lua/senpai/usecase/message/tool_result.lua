local utils = require("senpai.usecase.utils")

local M = {}

-- index: content
--  x:       [[
--  0:
--  1:
--  2: <SenpaiEditFile>
--  3:
--  4: filepath: `%s`
--  5:
--  6: <SenapiSearch>
--  7:
--  8: ```%s
--  9: %s
-- 10: ```
-- 11:
-- 12: </SenapiSearch>
-- 13: <SenapiReplace>
-- 14:
-- 15: ```%s
-- 16: %s
-- 17: ```
-- 18:
-- 19: </SenapiReplace>
-- 20:
-- 21: </SenpaiEditFile>
-- 22: ]],

---@param chat senpai.ChatWindow
local function render_virt_text(chat, start_row, end_row, result)
  local namespace = vim.api.nvim_create_namespace("sepnai-chat")
  local start_index = start_row - 1 -- 0 based

  local start_tag_index = start_index + 2
  local end_tag_index = end_row - 1

  vim.api.nvim_buf_set_extmark(
    chat.chat_log.bufnr,
    namespace,
    start_tag_index, -- 0-based
    0,
    {
      sign_text = "󰬲",
      sign_hl_group = "DiagnosticInfo",
      virt_text = { { "Edit File" } },
      virt_text_pos = "inline",
    }
  )
  vim.api.nvim_buf_set_extmark(
    chat.chat_log.bufnr,
    namespace,
    start_tag_index, -- 0-based
    0,
    {
      virt_text = { { "apply [a/A]" } },
      virt_text_pos = "right_align",
    }
  )

  local start_flod_index = start_index + 5
  local end_flod_index = start_flod_index
    + 2
    + #vim.split(result.searchText, "\n")
    + 4
  vim.api.nvim_win_call(chat.chat_log.winid, function()
    vim.cmd(start_flod_index + 1 .. "," .. end_flod_index + 1 .. " fold")
  end)

  for i = start_tag_index + 1, end_tag_index - 1 do
    vim.api.nvim_buf_set_extmark(
      chat.chat_log.bufnr,
      namespace,
      i, -- 0-based
      0,
      {
        sign_text = "▕",
        sign_hl_group = "DiagnosticVirtualInfo",
      }
    )
  end
end

---@param chat senpai.ChatWindow
---@param result table|string
local function render_base(chat, result)
  if result == nil then
    return
  end
  if type(result) == "string" then
    utils.set_text_at_last(chat.chat_log.bufnr, result)
    return
  end

  local start_row = vim.fn.line("$", chat.chat_log.winid)
  if result.toolName == "EditFile" then
    local render_text = string.format(
      [[


<SenpaiEditFile>

filepath: `%s`

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
      utils.get_relative_path(result.filepath),
      result.filetype,
      result.searchText,
      result.filetype,
      result.replaceText
    )
    utils.set_text_at_last(chat.chat_log.bufnr, render_text)
    local end_row = vim.fn.line("$", chat.chat_log.winid)
    render_virt_text(chat, start_row, end_row, result)
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
  render_base(chat, content.result)
end

return M
