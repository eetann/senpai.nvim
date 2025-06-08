local Helpers = dofile("tests/helpers.lua")
local child = Helpers.new_child_neovim()
local expect, eq = Helpers.expect, Helpers.expect.equality

local sleep = function(ms)
  Helpers.sleep(ms, child)
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.lua([[M=require("senpai.usecase.message.assistant")]])
    end,
    post_once = child.stop,
  },
})

T["<write_to_file>"] = MiniTest.new_set()

T["tool_result: WriteToFile block is rendered"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_write_to_file" } }
  )
  child.lua([[chat:show()]])
  local bufnr = child.lua_get([[chat.log_area.bufnr]])

  local tool_result_part = {
    toolCallId = "WriteToFile-2025-01-01",
    toolName = "WriteToFile",
    result = {
      path = "test.js",
      content = "console.log('hello world');",
    },
  }
  child.lua(
    'require("senpai.usecase.message.tool_result").render_from_memory(chat, ...)',
    { tool_result_part }
  )

  eq(child.get_line(bufnr, -6), "> [!NOTE] WriteToFile")
  eq(child.get_line(bufnr, -5), "> test.js")
  eq(child.get_line(bufnr, -4), "> ```javascript")
  eq(child.get_line(bufnr, -3), "> console.log('hello world');")
  eq(child.get_line(bufnr, -2), "> ```")
  eq(child.get_line(bufnr, -1), "")
end

T["tool_result: WriteToFile multiline content is rendered"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_write_to_file_multiline" } }
  )
  child.lua([[chat:show()]])
  local bufnr = child.lua_get([[chat.log_area.bufnr]])

  local tool_result_part = {
    toolCallId = "WriteToFile-2025-01-01",
    toolName = "WriteToFile",
    result = {
      path = "config.json",
      content = '{\n  "name": "test",\n  "version": "1.0.0"\n}',
    },
  }
  child.lua(
    'require("senpai.usecase.message.tool_result").render_from_memory(chat, ...)',
    { tool_result_part }
  )

  eq(child.get_line(bufnr, -9), "> [!NOTE] WriteToFile")
  eq(child.get_line(bufnr, -8), "> config.json")
  eq(child.get_line(bufnr, -7), "> ```json")
  eq(child.get_line(bufnr, -6), "> {")
  eq(child.get_line(bufnr, -5), '>   "name": "test",')
  eq(child.get_line(bufnr, -4), '>   "version": "1.0.0"')
  eq(child.get_line(bufnr, -3), "> }")
  eq(child.get_line(bufnr, -2), "> ```")
  eq(child.get_line(bufnr, -1), "")
end

T["tool_result: WriteToFile success message is rendered"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_write_to_file_success" } }
  )
  child.lua([[chat:show()]])
  local bufnr = child.lua_get([[chat.log_area.bufnr]])

  local tool_result_part = {
    toolName = "WriteToFile",
    args = {
      path = "new_file.txt",
    },
  }
  child.lua(
    'require("senpai.usecase.message.tool_result").render_from_memory(chat, ...)',
    { tool_result_part }
  )

  local action_result_part = {
    role = "user",
    content = "[write_to_file] Result:\n\nSuccessfully wrote to new_file.txt",
  }

  child.lua(
    'require("senpai.usecase.message.user").render_from_memory(chat, ...)',
    { action_result_part }
  )

  -- Check that the action result is rendered as a block quote
  local lines = child.get_lines(bufnr)

  assert(#lines >= 11, "Expected at least 11 lines but got " .. #lines)
  eq(lines[#lines - 6], "> [!NOTE] API Request")
  eq(lines[#lines - 5], "> [write_to_file] Result:")
  eq(lines[#lines - 4], "> ")
  eq(lines[#lines - 3], "> ")
  eq(lines[#lines - 2], "> Successfully wrote to new_file.txt")
  eq(lines[#lines - 1], "")
  eq(lines[#lines], "") -- Empty line after quote block
end

T["tool_result: WriteToFile error message is rendered"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_write_to_file_error" } }
  )
  child.lua([[chat:show()]])
  local bufnr = child.lua_get([[chat.log_area.bufnr]])

  local tool_result_part = {
    toolName = "WriteToFile",
    args = {
      path = "readonly_file.txt",
    },
  }
  child.lua(
    'require("senpai.usecase.message.tool_result").render_from_memory(chat, ...)',
    { tool_result_part }
  )

  local action_result_part = {
    role = "user",
    content = "[write_to_file] Result:\n\nFailed to write to readonly_file.txt: permission denied",
  }

  child.lua(
    'require("senpai.usecase.message.user").render_from_memory(chat, ...)',
    { action_result_part }
  )

  local lines = child.get_lines(bufnr)
  eq(lines[#lines - 6], "> [!NOTE] API Request")
  eq(lines[#lines - 5], "> [write_to_file] Result:")
  eq(lines[#lines - 4], "> ")
  eq(lines[#lines - 3], "> ")
  eq(
    lines[#lines - 2],
    "> Failed to write to readonly_file.txt: permission denied"
  )
  eq(lines[#lines - 1], "")
  eq(lines[#lines], "") -- Empty line after quote block
end

return T

