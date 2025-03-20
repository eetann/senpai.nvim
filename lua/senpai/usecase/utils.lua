local M = {}

---@param winid number
---@return { row:number, col:number }
function M.get_end_position1based(winid)
  local row = vim.fn.line("$", winid)
  local col = vim.fn.col({ row, "$" }, winid)
  return { row = row, col = col }
end

function M.set_text_1based_position(buffer, position, lines)
  vim.api.nvim_buf_set_text(
    buffer,
    -- 0-based
    position.row - 1,
    position.col - 1,
    position.row - 1,
    position.col - 1,
    lines
  )
end

---@param buffer number
---@param text string
function M.set_text_at_last(buffer, text)
  local lines = vim.split(text, "\n")
  vim.api.nvim_buf_set_text(buffer, -1, -1, -1, -1, lines)
end

---set winbar
---@param winid number
---@param text string
function M.set_winbar(winid, text)
  vim.api.nvim_set_option_value(
    "winbar",
    "%#Nomal#%=" .. text .. "%=",
    { win = winid, scope = "local" }
  )
end

---@param chat senpai.ChatWindow
function M.scroll_when_invisible(chat)
  local winid = chat.chat_log.winid
  local last_buffer_line = vim.fn.line("$", winid)
  local last_visible_line = vim.fn.line("w$", winid)
  if last_visible_line < last_buffer_line then
    vim.api.nvim_win_call(chat.chat_log.winid, function()
      vim.cmd("normal! G")
    end)
  end
end

---@param chat senpai.ChatWindow
---@param user_input string|string[]
---@return string user_input
function M.process_user_input(chat, user_input)
  local start_row = vim.fn.line("$", chat.chat_log.winid)
  local line_number = 1
  if type(user_input) == "table" then
    line_number = #user_input
    user_input = table.concat(user_input, "\n")
  else
    line_number = #vim.split(user_input, "\n")
  end
  local render_text = string.format(
    [[

<SenpaiUserInput>

%s

</SenpaiUserInput>
]],
    user_input
  )

  -- user input
  M.set_text_at_last(chat.chat_log.bufnr, render_text)
  M.create_borders(chat.chat_log.bufnr, start_row, line_number)
  M.scroll_when_invisible(chat)
  return user_input
end

function M.create_borders(bufnr, start_row, user_input_row_length)
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

return M
