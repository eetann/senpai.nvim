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

  -- Build quote block text
  local quote_lines = {
    "> [!NOTE] API Request",
    "> " .. header,
    "> ",
  }

  -- Add content lines with proper quoting
  for _, line in ipairs(vim.split(content, "\n")) do
    table.insert(quote_lines, "> " .. line)
  end

  local render_text = table.concat(quote_lines, "\n")
  if not chat.is_first_message then
    render_text = "\n\n" .. render_text
    start_row = start_row + 2
  end

  utils.set_text_at_last(chat.log_area.bufnr, render_text)

  -- Initially collapse the content (skip first 2 lines of header)
  local namespace = vim.api.nvim_create_namespace("senpai-action-result-fold")
  local content_start_row = start_row + 2 -- 0-based, skip "[!NOTE]" and header lines
  local content_line_count = #vim.split(content, "\n") + 1 -- +1 for empty line

  for i = 0, content_line_count - 1 do
    vim.api.nvim_buf_set_extmark(
      chat.log_area.bufnr,
      namespace,
      content_start_row + i,
      0,
      {
        conceal = "",
        hl_group = "SenpaiToolResultFold",
      }
    )
  end

  -- Add initial collapsed arrow overlay
  vim.api.nvim_buf_set_extmark(chat.log_area.bufnr, namespace, start_row, 0, {
    virt_text = { { "▷", "Comment" } },
    virt_text_pos = "overlay",
    id = 1000000 + start_row, -- Unique ID for arrow extmark
  })

  utils.scroll_when_invisible(chat)
end

---Get block quote range at cursor position
---@param row integer 1-based row
---@param bufnr integer
---@return {start_line: integer, end_line: integer}|nil
function M.get_block_quote_range(row, bufnr)
  local parser = vim.treesitter.get_parser(bufnr, "markdown")
  if not parser then
    return nil
  end

  -- Force parser to update
  parser:parse(true)
  local tree = parser:parse()[1]
  local root = tree:root()

  local node = root:named_descendant_for_range(row - 1, 0, row - 1, 0)
  while node do
    if node:type() == "block_quote" then
      local start_row, _, end_row, _ = node:range()
      return { start_line = start_row, end_line = end_row - 1 }
    end
    node = node:parent()
  end
  return nil
end

---Check if current line is an API Request header
---@param bufnr integer
---@param line integer 0-based
---@return boolean
function M.is_api_request_header(bufnr, line)
  local line_text = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
  return line_text and line_text:match("^> %[!NOTE%] API Request$") ~= nil
end

---Toggle fold state for action result block quote
---@param bufnr integer
---@param quote_range {start_line: integer, end_line: integer}
function M.toggle_action_result_fold(bufnr, quote_range)
  local namespace = vim.api.nvim_create_namespace("senpai-action-result-fold")

  -- Check if first line is API Request header
  if not M.is_api_request_header(bufnr, quote_range.start_line) then
    return
  end

  -- Check current fold state by looking for conceal on content lines
  local content_start = quote_range.start_line + 1
  local extmarks = vim.api.nvim_buf_get_extmarks(
    bufnr,
    namespace,
    { content_start, 0 },
    { content_start, -1 },
    { details = true }
  )

  local is_folded = false
  for _, extmark in ipairs(extmarks) do
    ---@diagnostic disable: undefined-field
    if extmark[4] and extmark[4].conceal_lines == "" then
      is_folded = true
      break
    end
  end

  -- Clear existing extmarks in the quote range
  vim.api.nvim_buf_clear_namespace(
    bufnr,
    namespace,
    quote_range.start_line,
    quote_range.end_line + 1
  )

  if is_folded then
    -- Expand: show content with down arrow
    vim.api.nvim_buf_set_extmark(bufnr, namespace, quote_range.start_line, 0, {
      virt_text = { { "▽", "Comment" } },
      virt_text_pos = "overlay",
      id = 1000000 + quote_range.start_line,
    })
  else
    -- Collapse: hide content with right arrow
    for i = content_start, quote_range.end_line do
      vim.print("conceal: " .. i)
      vim.api.nvim_buf_set_extmark(bufnr, namespace, i, 0, {
        conceal_lines = "",
        hl_group = "SenpaiToolResultFold",
      })
    end

    vim.api.nvim_buf_set_extmark(bufnr, namespace, quote_range.start_line, 0, {
      virt_text = { { "▷", "Comment" } },
      virt_text_pos = "overlay",
      id = 1000000 + quote_range.start_line,
    })
  end
end

return M
