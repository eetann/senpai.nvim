local utils = require("senpai.usecase.utils")
local ActionResultRenderer =
  require("senpai.usecase.message.action_result_renderer")
local M = {}

local function removeReferenceSection(text)
  -- \n---\n\nReference
  local result = string.gsub(text, "\n%-%-%-\n\nReference.-$", "")
  return result
end

---Extract content from task or user_feedback tags
---@param text string
---@return string tag_content
---@return string|nil other_content
local function extract_tag_content(text)
  -- Check for <task> tag
  local task_content = text:match("<task>(.-)</task>")
  if task_content then
    local other =
      text:gsub("<task>.-</task>", ""):gsub("^%s+", ""):gsub("%s+$", "")
    return task_content, other ~= "" and other or nil
  end

  -- Check for <user_feedback> tag
  local feedback_content = text:match("<user_feedback>(.-)</user_feedback>")
  if feedback_content then
    local other = text
      :gsub("<user_feedback>.-</user_feedback>", "")
      :gsub("^%s+", "")
      :gsub("%s+$", "")
    return feedback_content, other ~= "" and other or nil
  end

  -- No tags found, return original text
  return text, nil
end

-- index: content
-- x: [[
-- 0: <SenpaiUserInput>
-- 1:
-- 2: %s
-- 3:
-- 4: </SenpaiUserInput>
-- 5: ]],

---@param bufnr number
---@param start_row number
---@param user_input_row_length number
function M.render_border(bufnr, start_row, user_input_row_length)
  local namespace = vim.api.nvim_create_namespace("sepnai-chat")
  local start_tag_index = start_row - 1 -- 0 based
  local end_tag_index = start_tag_index + 1 + user_input_row_length + 2
  -- NOTE: I want to use only virt_text to put indent,
  -- but it shifts during `set wrap`, so I also use sign_text.

  -- border top
  vim.api.nvim_buf_set_extmark(
    bufnr,
    namespace,
    start_tag_index + 1, -- 0-based
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
  for i = start_tag_index + 2, end_tag_index - 2 do
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
    end_tag_index - 1, -- 0-based
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
---@param other_content string|nil
local function base_render(chat, user_input, other_content)
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
  if not chat.is_first_message then
    render_text = "\n\n" .. render_text
    start_row = start_row + 2
  end

  -- user input
  utils.set_text_at_last(chat.log_area.bufnr, render_text)
  M.render_border(chat.log_area.bufnr, start_row, line_number)

  if not other_content then
    return
  end
  -- Render other content with folding if exists
  local other_start_row = vim.fn.line("$", chat.log_area.winid)
  utils.set_text_at_last(chat.log_area.bufnr, "\n\n" .. other_content)

  -- Add folding for other content
  local namespace = vim.api.nvim_create_namespace("sepnai-chat")
  local other_lines = vim.split(other_content, "\n")
  for i = 0, #other_lines - 1 do
    vim.api.nvim_buf_set_extmark(
      chat.log_area.bufnr,
      namespace,
      other_start_row + 1 + i, -- 0-based, +1 for the empty line
      0,
      {
        conceal_lines = "",
      }
    )
  end

  utils.scroll_when_invisible(chat)
end

---@param chat senpai.IChatWindow
---@param message senpai.chat.message.user
function M.render_from_memory(chat, message)
  local content = message.content
  local full_text = ""

  if type(content) == "string" then
    full_text = removeReferenceSection(content)
  else
    -- content is `senpai.chat.message.user.part[]`
    for _, part in pairs(content) do
      if part.type == "text" then
        full_text = full_text .. removeReferenceSection(part.text)
      end
    end
  end

  -- Check if this is an action result first
  if ActionResultRenderer.is_action_result(full_text) then
    local header, content_part =
      ActionResultRenderer.extract_action_result(full_text)
    if header and content_part then
      ActionResultRenderer.render_action_result(chat, header, content_part)
      return
    end
  end

  -- Extract tag content and other content for normal user messages
  local tag_content, other_content = extract_tag_content(full_text)
  local lines = {}
  for _, text in pairs(vim.split(tag_content, "\n")) do
    table.insert(lines, text)
  end
  base_render(chat, lines, other_content)
end

---@param chat senpai.IChatWindow
---@param user_input string[]
function M.render_from_request(chat, user_input)
  vim.api.nvim_buf_set_lines(chat.input_area.bufnr, 0, -1, false, {})

  -- Check if this is an action result
  local full_text = table.concat(user_input, "\n")
  if ActionResultRenderer.is_action_result(full_text) then
    local header, content =
      ActionResultRenderer.extract_action_result(full_text)
    if header and content then
      ActionResultRenderer.render_action_result(chat, header, content)
      return
    end
  end

  base_render(chat, user_input, nil) -- No other content for request rendering
end

return M
