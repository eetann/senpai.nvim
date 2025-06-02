local Helpers = dofile("tests/helpers.lua")
---@type NvimChild
local child = Helpers.new_child_neovim()
local expect, eq = Helpers.expect, Helpers.expect.equality

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.lua([[M=require("senpai.usecase.message.user")]])
    end,
    post_once = child.stop,
  },
})

T["render_border creates proper extmarks"] = function()
  local buffer = child.api.nvim_get_current_buf()
  local lines = {
    "<SenpaiUserInput>",
    "",
    "foooooooooooooo",
    "",
    "</SenpaiUserInput>",
    "",
  }
  child.api.nvim_buf_set_lines(buffer, 0, -1, true, lines)

  local start_row = 1 -- at <SenpaiUserInput>
  local user_input_row_length = 1
  child.lua(
    "M.render_border(...)",
    { buffer, start_row, user_input_row_length }
  )

  local namespace = child.lua_get([[
    vim.api.nvim_create_namespace("sepnai-chat")
  ]])

  local extmarks = child.lua_get(
    [[
    vim.api.nvim_buf_get_extmarks(...)
  ]],
    { buffer, namespace, 0, -1, { details = true } }
  )

  eq(#extmarks >= 3, true) -- top, left, bottom

  local top_border_found = false
  local bottom_border_found = false
  for _, mark in ipairs(extmarks) do
    local details = mark[4]
    -- top
    if details.sign_text:find("╭") then
      top_border_found = true
      eq(details.sign_hl_group, "FloatBorder")
      eq(details.virt_text[1][2], "FloatBorder")
    end
    -- bottom
    if details.sign_text:find("╰") then
      bottom_border_found = true
      eq(details.sign_hl_group, "FloatBorder")
      eq(details.virt_text[1][2], "FloatBorder")
    end
  end

  eq(top_border_found, true)
  eq(bottom_border_found, true)

  -- left
  local left_border_count = 0
  for _, mark in ipairs(extmarks) do
    local details = mark[4]
    if details.sign_text:find("│") then
      left_border_count = left_border_count + 1
      eq(details.sign_hl_group, "FloatBorder")
    end
  end

  expect.reference_screenshot(child.get_screenshot())
  -- The left text should exist for the number of lines
  --  between the top and bottom frames
  eq(left_border_count, 1)
end

T["render_border positions borders correctly"] = function()
  local buffer = child.api.nvim_get_current_buf()
  local start_row = 5
  local user_input_row_length = 2

  local lines = {}
  for i = 1, start_row - 1 do
    table.insert(lines, "foo" .. i)
  end
  table.insert(lines, "<SenpaiUserInput>")
  table.insert(lines, "")
  table.insert(lines, "foooooooooooooooooo")
  table.insert(lines, "foooooooooooooooooo")
  table.insert(lines, "")
  table.insert(lines, "</SenpaiUserInput>")
  table.insert(lines, "")
  child.api.nvim_buf_set_lines(buffer, 0, -1, true, lines)

  child.lua(
    "M.render_border(...)",
    { buffer, start_row, user_input_row_length }
  )
  local namespace = child.lua_get([[
    vim.api.nvim_create_namespace("sepnai-chat")
  ]])

  local extmarks = child.lua_get(
    [[
    vim.api.nvim_buf_get_extmarks(...)
  ]],
    { buffer, namespace, 0, -1, { details = true } }
  )

  local top_border_row = -1
  local bottom_border_row = -1

  for _, mark in ipairs(extmarks) do
    -- { 1, 5, 0, -- extmark_id, row, col
    --   {
    --     ns_id = 3,
    --     priority = 4096,
    --     right_gravity = true,
    --     sign_hl_group = "FloatBorder",
    --     sign_text = "╭ ",
    --     virt_text = { { "text", "FloatBorder", }, },
    --     virt_text_hide = true,
    --     virt_text_pos = "overlay",
    --     virt_text_repeat_linebreak = false,
    --   },
    -- })
    local row = mark[2]
    local details = mark[4]

    if details.sign_text:find("╭") then
      top_border_row = row + 1
    elseif details.sign_text:find("╰") then
      bottom_border_row = row + 1
    end
  end
  expect.reference_screenshot(child.get_screenshot())
  eq(Helpers.get_line(child, 0, top_border_row - 1), "<SenpaiUserInput>")
  eq(Helpers.get_line(child, 0, top_border_row), "")
  eq(Helpers.get_line(child, 0, bottom_border_row), "")
  eq(Helpers.get_line(child, 0, bottom_border_row + 1), "</SenpaiUserInput>")
end

T["render_from_memory extracts task tag content"] = function()
  local buffer = child.api.nvim_create_buf(false, true)

  -- Mock chat object
  local chat = child.lua_get([[{
    log_area = { bufnr = ]] .. buffer .. [[, winid = vim.api.nvim_get_current_win() },
    is_first_message = true
  }]])

  -- Message with task tag
  local message = {
    content = "<task>This is the task content</task>\n[some_tool] Result:\nThis is other content",
  }

  child.lua("M.render_from_memory(...)", { chat, message })

  local lines = child.api.nvim_buf_get_lines(buffer, 0, -1, false)

  -- Check that only task content is shown in the main area
  local found_task = false
  local found_other = false
  for _, line in ipairs(lines) do
    if line:find("This is the task content") then
      found_task = true
    end
    if line:find("This is other content") then
      found_other = true
    end
  end

  eq(found_task, true)
  eq(found_other, true) -- Other content should be rendered but concealed
end

T["render_from_memory extracts user_feedback tag content"] = function()
  local buffer = child.api.nvim_create_buf(false, true)

  -- Mock chat object
  local chat = child.lua_get([[{
    log_area = { bufnr = ]] .. buffer .. [[, winid = vim.api.nvim_get_current_win() },
    is_first_message = false
  }]])

  -- Message with user_feedback tag
  local message = {
    content = "<user_feedback>This is user feedback</user_feedback>\n[tool_name] Result:\nTool execution result",
  }

  child.lua("M.render_from_memory(...)", { chat, message })

  local lines = child.api.nvim_buf_get_lines(buffer, 0, -1, false)

  -- Check that only feedback content is shown in the main area
  local found_feedback = false
  local found_tool_result = false
  for _, line in ipairs(lines) do
    if line:find("This is user feedback") then
      found_feedback = true
    end
    if line:find("Tool execution result") then
      found_tool_result = true
    end
  end

  eq(found_feedback, true)
  eq(found_tool_result, true)
end

T["render_from_memory conceals other content"] = function()
  local buffer = child.api.nvim_create_buf(false, true)

  -- Mock chat object
  local chat = child.lua_get([[{
    log_area = { bufnr = ]] .. buffer .. [[, winid = vim.api.nvim_get_current_win() },
    is_first_message = true
  }]])

  -- Message with task tag and other content
  local message = {
    content = "<task>Main task</task>\n[tool] Result:\nLine 1\nLine 2\nLine 3",
  }

  child.lua("M.render_from_memory(...)", { chat, message })

  local namespace = child.lua_get([[
    vim.api.nvim_create_namespace("sepnai-chat")
  ]])

  local extmarks = child.lua_get(
    [[
    vim.api.nvim_buf_get_extmarks(...)
  ]],
    { buffer, namespace, 0, -1, { details = true } }
  )

  -- Count concealed lines
  local conceal_count = 0
  for _, mark in ipairs(extmarks) do
    local details = mark[4]
    if details.conceal_lines ~= nil then
      conceal_count = conceal_count + 1
    end
  end

  -- Should have concealed lines for the other content
  eq(conceal_count >= 3, true) -- At least 3 lines of other content
end

return T
