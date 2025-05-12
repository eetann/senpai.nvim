local utils = require("senpai.usecase.utils")

local M = {}

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
    chat.log_area.bufnr,
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
    chat.log_area.bufnr,
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
  vim.api.nvim_win_call(chat.log_area.winid, function()
    vim.cmd(start_search_fold_index + 1 .. "," .. end_tag_index .. " fold")
  end)

  for i = start_tag_index + 1, end_tag_index - 1 do
    vim.api.nvim_buf_set_extmark(
      chat.log_area.bufnr,
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
    utils.set_text_at_last(chat.log_area.bufnr, part.result)
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
