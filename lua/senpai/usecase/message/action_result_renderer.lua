local utils = require("senpai.usecase.utils")

local M = {}

---Check if the input is an action result
---@param text string
---@return boolean
function M.is_action_result(text)
  return text:match("^%[[%w_]+%] Result:\n") ~= nil
end

---Extract action result header and content
---@param text string
---@return string|nil header
---@return string|nil content
function M.extract_action_result(text)
  local header, content = text:match("^(%[[%w_]+%] Result:)\n(.*)$")
  if header and content then
    return header, content
  end
  return nil, nil
end

---Render action result with collapsible content
---@param chat senpai.IChatWindow
---@param header string
---@param content string
function M.render_action_result(chat, header, content)
  local start_row = vim.fn.line("$", chat.log_area.winid)
  local header_lines = vim.split(header, "\n")
  local content_lines = vim.split(content, "\n")

  -- Render header (always visible)
  local render_text = header
  if not chat.is_first_message then
    render_text = "\n\n" .. render_text
    start_row = start_row + 2
  end

  utils.set_text_at_last(chat.log_area.bufnr, render_text)

  -- Render content (initially collapsed)
  utils.set_text_at_last(chat.log_area.bufnr, "\n\n" .. content)

  -- Add folding for content
  local namespace = vim.api.nvim_create_namespace("sepnai-chat")
  for i = 0, 1 + #content_lines - 1 do
    vim.api.nvim_buf_set_extmark(
      chat.log_area.bufnr,
      namespace,
      start_row + 1 + i, -- 0-based, +1 for the empty line
      0,
      {
        conceal_lines = "",
        hl_group = "SenpaiToolResultFold",
      }
    )
  end

  -- Add keymap for toggling fold on the header line
  -- これだと複数のツールが有る時に対応できない
  vim.keymap.set("n", "<CR>", function()
    local current_line = vim.fn.line(".")
    if
      current_line >= start_row
      and current_line <= start_row + #header_lines + 3
    then
      M.toggle_action_result_fold(
        chat.log_area.bufnr,
        start_row + 1,
        #content_lines
      )
    end
  end, {
    buffer = chat.log_area.bufnr,
    desc = "Toggle action result fold",
  })

  utils.scroll_when_invisible(chat)
end

---Toggle fold state for action result content
---@param bufnr number
---@param start_line number
---@param line_count number
function M.toggle_action_result_fold(bufnr, start_line, line_count)
  local namespace = vim.api.nvim_create_namespace("sepnai-chat")

  -- Check current fold state by looking at the first line's extmark
  local extmarks = vim.api.nvim_buf_get_extmarks(
    bufnr,
    namespace,
    { start_line - 1, 0 }, -- 0-based
    { start_line - 1, -1 },
    { details = true }
  )

  local is_folded = false
  for _, extmark in ipairs(extmarks) do
    if extmark[4] and extmark[4].conceal_lines == "" then
      is_folded = true
      break
    end
  end

  -- Toggle fold state
  for i = 0, line_count - 1 do
    local line_idx = start_line - 1 + i -- 0-based

    -- Clear existing extmarks on this line
    local existing_marks = vim.api.nvim_buf_get_extmarks(
      bufnr,
      namespace,
      { line_idx, 0 },
      { line_idx, -1 },
      {}
    )

    for _, mark in ipairs(existing_marks) do
      vim.api.nvim_buf_del_extmark(bufnr, namespace, mark[1])
    end

    -- Set new extmark based on toggle state
    if is_folded then
      -- Show content
      vim.api.nvim_buf_set_extmark(bufnr, namespace, line_idx, 0, {
        hl_group = "SenpaiToolResultFold",
      })
    else
      -- Hide content
      vim.api.nvim_buf_set_extmark(bufnr, namespace, line_idx, 0, {
        conceal_lines = "",
        hl_group = "SenpaiToolResultFold",
      })
    end
  end
end

return M
