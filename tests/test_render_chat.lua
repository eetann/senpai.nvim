local Helpers = dofile("tests/helpers.lua")
local child = Helpers.new_child_neovim()
local expect, eq = Helpers.expect, Helpers.expect.equality

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.load()
      child.lua([[M=require("senpai.usecase.send_text")]])
    end,
    post_once = child.stop,
  },
})

T["create_borders creates proper extmarks"] = function()
  local buffer = child.api.nvim_get_current_buf()
  local lines = {
    "",
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
    "M.create_borders(...)",
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
      eq(details.sign_hl_group, "NonText")
      eq(details.virt_text[1][2], "NonText")
    end
    -- bottom
    if details.sign_text:find("╰") then
      bottom_border_found = true
      eq(details.sign_hl_group, "NonText")
      eq(details.virt_text[1][2], "NonText")
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
      eq(details.sign_hl_group, "NonText")
    end
  end

  -- The left text should exist for the number of lines
  --  between the top and bottom frames
  eq(left_border_count >= 3, true)
end

T["create_borders positions borders correctly"] = function()
  local buffer = child.api.nvim_get_current_buf()
  local start_row = 5
  local user_input_row_length = 2

  local lines = {}
  for i = 1, start_row - 1 do
    table.insert(lines, "foo" .. i)
  end
  table.insert(lines, "")
  table.insert(lines, "<SenpaiUserInput>")
  table.insert(lines, "")
  table.insert(lines, "foooooooooooooooooo")
  table.insert(lines, "foooooooooooooooooo")
  table.insert(lines, "")
  table.insert(lines, "</SenpaiUserInput>")
  table.insert(lines, "")
  child.api.nvim_buf_set_lines(buffer, 0, -1, true, lines)

  child.lua(
    "M.create_borders(...)",
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
    --     sign_hl_group = "NonText",
    --     sign_text = "╭ ",
    --     virt_text = { { "text", "NonText", }, },
    --     virt_text_hide = true,
    --     virt_text_pos = "overlay",
    --     virt_text_repeat_linebreak = false,
    --   },
    -- })
    local row = mark[2]
    local details = mark[4]

    if details.sign_text:find("╭") then
      top_border_row = row
    elseif details.sign_text:find("╰") then
      bottom_border_row = row
    end
  end

  eq(
    child.api.nvim_buf_get_lines(0, top_border_row, top_border_row + 1, true)[1],
    "<SenpaiUserInput>"
  )
  eq(
    child.api.nvim_buf_get_lines(
      0,
      bottom_border_row,
      bottom_border_row + 1,
      true
    )[1],
    "</SenpaiUserInput>"
  )
end

return T
