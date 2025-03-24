local utils = require("senpai.usecase.utils")

local M = {}

---@class senpai.tool.EditFile.result
---@field filepath string
---@field searchText string
---@field replaceText string
---@field filetype string

---@class senpai.tool.EditFile: senpai.chat.message.part.tool_result
---@field result senpai.tool.EditFile.result

-- index: content
--  x:        [[
--  0:
--  1:
--  2: <SenpaiEditFile>
--  3:
--  4: filepath: `%s`
--  5: ```%s type="replace"
--  6: %s
--  7: ```
--  8: ```%s type="search"
--  9: %s
-- 10: ```
-- 11: </SenpaiEditFile>
-- 12: ]],

---@param chat senpai.IChatWindow
---@param start_row number
---@param end_row number
---@param part senpai.tool.EditFile
local function render_virt_text(chat, start_row, end_row, part)
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

  ---@type number
  local line_numer = #vim.split(part.result.replaceText, "\n")
  local start_search_fold_index = start_tag_index + 3 + line_numer + 2
  vim.api.nvim_win_call(chat.chat_log.winid, function()
    vim.cmd(start_search_fold_index + 1 .. "," .. end_tag_index .. " fold")
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

---@param chat senpai.IChatWindow
---@param part senpai.chat.message.part.tool_result
local function render_base(chat, part)
  if part.result == nil then
    return
  end
  if type(part.result) == "string" then
    utils.set_text_at_last(chat.chat_log.bufnr, part.result)
    return
  end

  local start_row = vim.fn.line("$", chat.chat_log.winid)
  if part.result.toolName == "EditFile" then
    ---@cast part senpai.tool.EditFile
    local render_text = string.format(
      [[


<SenpaiEditFile id="%s">

filepath: `%s`
```%s type="replace"
%s
```
```%s type="search"
%s
```
</SenpaiEditFile>
]],
      part.toolCallId,
      utils.get_relative_path(part.result.filepath),
      part.result.filetype,
      part.result.replaceText,
      part.result.filetype,
      part.result.searchText
    )
    utils.set_text_at_last(chat.chat_log.bufnr, render_text)
    local end_row = vim.fn.line("$", chat.chat_log.winid)
    render_virt_text(chat, start_row, end_row, part)
    -- TODO: ここでchatにいれる
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
    utils.set_text_at_last(chat.chat_log.bufnr, content .. "\n")
    return
  end
  render_base(chat, content)
end

return M
