local utils = require("senpai.usecase.utils")
local M = {}

-- index: content
-- x: [[
-- 0:
-- 1: <SenpaiUserInput>
-- 2:
-- 3: %s
-- 4:
-- 5: </SenpaiUserInput>
-- 6: ]],

---@param bufnr number
---@param start_row number
---@param user_input_row_length number
function M.render_border(bufnr, start_row, user_input_row_length)
  local namespace = vim.api.nvim_create_namespace("sepnai-chat")
  local start_index = start_row - 1 -- 0 based

  local start_tag_index = start_index + 1
  local end_tag_index = start_index + 2 + user_input_row_length + 2
  -- NOTE: I want to use only virt_text to put indent,
  -- but it shifts during `set wrap`, so I also use sign_text.

  -- border top
  vim.api.nvim_buf_set_extmark(
    bufnr,
    namespace,
    start_tag_index, -- 0-based
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
  for i = start_tag_index + 1, end_tag_index - 1 do
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
    end_tag_index, -- 0-based
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

---@param chat senpai.IChatWindow
---@param user_input string[]
local function base_render(chat, user_input)
  local start_row = vim.fn.line("$", chat.log_area.winid)
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
  utils.set_text_at_last(chat.log_area.bufnr, render_text)
  M.render_border(chat.log_area.bufnr, start_row, line_number)
  utils.scroll_when_invisible(chat)
end

---@param chat senpai.IChatWindow
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

---@param chat senpai.IChatWindow
---@param user_input string[]
function M.render_from_request(chat, user_input)
  vim.api.nvim_buf_set_lines(chat.input_area.bufnr, 0, -1, false, {})
  base_render(chat, user_input)
end

return M
