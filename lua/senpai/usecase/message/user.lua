local utils = require("senpai.usecase.utils")
local M = {}

local function create_borders(bufnr, start_row, user_input_row_length)
  local namespace = vim.api.nvim_create_namespace("sepnai-chat")
  local start_index = start_row - 1 -- 0 based

  local startTagIndex = start_index + 1
  local endTagIndex = start_index + 2 + user_input_row_length + 2
  -- NOTE: I want to use only virt_text to put indent,
  -- but it shifts during `set wrap`, so I also use sign_text.

  -- border top
  vim.api.nvim_buf_set_extmark(
    bufnr,
    namespace,
    startTagIndex, -- 0-based
    0,
    {
      sign_text = "╭",
      sign_hl_group = "FloatBorder",
      virt_text = { { string.rep("─", 150), "FloatBorder" } },
      virt_text_pos = "overlay",
      virt_text_hide = true,
    }
  )

  -- border left
  for i = startTagIndex + 1, endTagIndex - 1 do
    vim.api.nvim_buf_set_extmark(
      bufnr,
      namespace,
      i, -- 0-based
      0,
      {
        sign_text = "│",
        sign_hl_group = "FloatBorder",
      }
    )
  end

  -- border bottom
  vim.api.nvim_buf_set_extmark(
    bufnr,
    namespace,
    endTagIndex, -- 0-based
    0,
    {
      sign_text = "╰",
      sign_hl_group = "FloatBorder",
      virt_text = { { string.rep("─", 150), "FloatBorder" } },
      virt_text_pos = "overlay",
      virt_text_hide = true,
    }
  )
end

---@param chat senpai.ChatWindow
---@param user_input string[]
---@return string user input text for send to LLM
local function base_render(chat, user_input)
  local start_row = vim.fn.line("$", chat.chat_log.winid)
  local line_number = #user_input
  local texts = table.concat(user_input, "\n")
  local render_text = string.format(
    [[

<SenpaiUserInput>

%s

</SenpaiUserInput>
]],
    texts
  )

  -- user input
  utils.set_text_at_last(chat.chat_log.bufnr, render_text)
  create_borders(chat.chat_log.bufnr, start_row, line_number)
  utils.scroll_when_invisible(chat)
  return texts
end

---@param chat senpai.ChatWindow
---@param message senpai.chat.message.user
function M.render_from_memory(chat, message)
  local content = message.content
  if type(content) == "string" then
    base_render(chat, { content })
    return
  end
  -- content is `senpai.chat.message.user.part[]`
  local lines = {}
  for _, part in pairs(content) do
    if part.type == "text" then
      table.insert(lines, unpack(vim.split(part.text, "\n")))
    end
  end
  base_render(chat, lines)
end

---@param chat senpai.ChatWindow
---@return string user input text for send to LLM
function M.render_from_input(chat)
  local lines = vim.api.nvim_buf_get_lines(chat.chat_input.bufnr, 0, -1, false)
  vim.api.nvim_buf_set_lines(chat.chat_input.bufnr, 0, -1, false, {})
  return base_render(chat, lines)
end

return M
