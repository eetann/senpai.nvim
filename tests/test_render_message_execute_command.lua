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

T["<execute_command>"] = MiniTest.new_set()

T["tool_result: ExecuteCommand block is rendered"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_execute_command" } }
  )
  child.lua([[chat:show()]])
  local bufnr = child.lua_get([[chat.log_area.bufnr]])

  local tool_result_part = {
    toolCallId = "ExecuteCommand-2025-04-20",
    toolName = "ExecuteCommand",
    result = {
      command = "mv foo.js bar.js",
    },
  }
  child.lua(
    'require("senpai.usecase.message.tool_result").render_from_memory(chat, ...)',
    { tool_result_part }
  )

  eq(child.get_line(bufnr, -5), "> [!NOTE] ExecuteCommand")
  eq(child.get_line(bufnr, -4), "> ```sh")
  eq(child.get_line(bufnr, -3), "> mv foo.js bar.js")
  eq(child.get_line(bufnr, -2), "> ```")
  eq(child.get_line(bufnr, -1), "")
end

T["tool_result: ExecuteCommand success message is rendered"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_execute_command" } }
  )
  child.lua([[chat:show()]])
  local bufnr = child.lua_get([[chat.log_area.bufnr]])

  local tool_result_part = {
    toolName = "ExecuteCommand",
    args = {
      command = "mv foo.js bar.js",
    },
  }
  child.lua(
    'require("senpai.usecase.message.tool_result").render_from_memory(chat, ...)',
    { tool_result_part }
  )

  local action_result_part =
    { role = "user", content = "[execute_command] Result:\n\nSuccess" }

  child.lua(
    'require("senpai.usecase.message.user").render_from_memory(chat, ...)',
    { action_result_part }
  )

  -- TODO: SenpaiUserInputを消す
  eq(child.get_lines(bufnr), "")
  eq(child.get_line(bufnr, -3), "[execute_command] Result:")
  eq(child.get_line(bufnr, -2), "")
  eq(child.get_line(bufnr, -1), "Success")
end

T["tool_result: ExecuteCommand error message is rendered"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_execute_command" } }
  )
  child.lua([[chat:show()]])
  local bufnr = child.lua_get([[chat.log_area.bufnr]])

  local tool_result_part = {
    toolName = "ExecuteCommand",
    args = {
      command = "mv foo.js bar.js",
    },
  }
  child.lua(
    'require("senpai.usecase.message.tool_result").render_from_memory(chat, ...)',
    { tool_result_part }
  )

  local action_result_part = {
    role = "user",
    content = "[execute_command] Result:\n\nError: permission denied",
  }

  child.lua(
    'require("senpai.usecase.message.user").render_from_memory(chat, ...)',
    { action_result_part }
  )

  eq(child.get_line(bufnr, -3), "[execute_command] Result:")
  eq(child.get_line(bufnr, -2), "")
  eq(child.get_line(bufnr, -1), "Error: permission denied")
end

return T
