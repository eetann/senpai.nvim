local Helpers = dofile("tests/helpers.lua")
local child = Helpers.new_child_neovim()
local expect, eq = Helpers.expect, Helpers.expect.equality

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.load()
      child.lua([[M=require("senpai.usecase.message.assistant")]])
    end,
    post_once = child.stop,
  },
})

T["assistant <replace_file> chunk process"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_assistant" } }
  )
  child.lua([[chat:show()]])
  local bufnr = child.lua_get([[chat.log_area.bufnr]])
  child.lua("assistant=M.new(chat)")
  eq(Helpers.get_line(child, bufnr, 5), "---")

  child.lua("assistant:process_chunk(...)", { "plain text " })
  eq(Helpers.get_line(child, bufnr, 6), "plain text ")
  eq(Helpers.get_line(child, bufnr, 7), nil)
  child.lua("assistant:process_chunk(...)", { "here.\n" })
  eq(Helpers.get_line(child, bufnr, 6), "plain text here.")
  eq(Helpers.get_line(child, bufnr, 7), "")
  eq(Helpers.get_line(child, bufnr, 8), nil)

  child.lua("assistant:process_chunk(...)", { "<replace" })
  eq(Helpers.get_line(child, bufnr, 6), "plain text here.")
  eq(Helpers.get_line(child, bufnr, 7), "<replace")
  child.lua("assistant:process_chunk(...)", { "_file>\n" })
  eq(Helpers.get_line(child, bufnr, 7), "")
  eq(
    Helpers.get_line(child, bufnr, 8):find([[<SenpaiReplaceFile id=".*">]])
      ~= nil,
    true
  )
  eq(Helpers.get_line(child, bufnr, 9), "")
  eq(Helpers.get_line(child, bufnr, 10), "")
  eq(Helpers.get_line(child, bufnr, 11), nil)

  child.lua("assistant:process_chunk(...)", { "<path>src/" })
  child.lua("assistant:process_chunk(...)", { "main.js" })
  child.lua("assistant:process_chunk(...)", { "</path>\n" })
  child.lua("assistant:process_chunk(...)", { "<search>\n" })
  child.lua("assistant:process_chunk(...)", { "  return a - b;\n" })
  child.lua("assistant:process_chunk(...)", { "</search>\n" })
  child.lua("assistant:process_chunk(...)", { "<replace>\n" })
  child.lua("assistant:process_chunk(...)", { "  return a + b;\n" })
  child.lua("assistant:process_chunk(...)", { "</replace>\n" })
  child.lua("assistant:process_chunk(...)", { "</replace_file>\n" })
  eq(Helpers.get_line(child, bufnr, 9), "")
  eq(Helpers.get_line(child, bufnr, 10), "filepath: src/main.js")
  eq(Helpers.get_line(child, bufnr, 11), "```javascript")
  eq(Helpers.get_line(child, bufnr, 12), "  return a + b;")
  eq(Helpers.get_line(child, bufnr, 13), "```")
  eq(Helpers.get_line(child, bufnr, 14), "")
  eq(Helpers.get_line(child, bufnr, 15), "</SenpaiReplaceFile>")
  child.lua("assistant:process_chunk(...)", { "red\nblue" })
  child.lua("assistant:process_chunk(...)", { " yellow green" })
  eq(Helpers.get_line(child, bufnr, 16), "red")
  eq(Helpers.get_line(child, bufnr, 17), "blue yellow green")
  eq(Helpers.get_line(child, bufnr, 18), nil)
end

T["assistant <replace_file> real"] = function()
  -- for screenshot
  child.o.lines, child.o.columns = 40, 60

  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_assistant" } }
  )
  child.lua([[chat:show()]])
  child.cmd("1windo close")
  local bufnr = child.lua_get([[chat.log_area.bufnr]])
  child.lua("assistant=M.new(chat)")
  eq(Helpers.get_line(child, bufnr, 5), "---")

  child.lua("assistant:process_chunk(...)", { "here:\n\n<replace_" })
  child.lua("assistant:process_chunk(...)", { "file>\n<path>lua" })
  eq(
    Helpers.get_line(child, bufnr, -3):find([[<SenpaiReplaceFile id=".*">]])
      ~= nil,
    true
  )
  child.lua("assistant:process_chunk(...)", { "/senpai/usecase/message/" })
  child.lua("assistant:process_chunk(...)", { "tool_call.lua</path>" })
  eq(
    child.lua_get([[assistant.line]]),
    "<path>lua/senpai/usecase/message/tool_call.lua</path>"
  )
  child.lua(
    "assistant:process_chunk(...)",
    { '\n<search>\nlocal utils = require("senp' }
  )
  eq(Helpers.get_line(child, bufnr, -3), "")
  eq(
    Helpers.get_line(child, bufnr, -2),
    "filepath: lua/senpai/usecase/message/tool_call.lua"
  )
  eq(Helpers.get_line(child, bufnr, -1), "")
  eq(child.lua_get([[assistant.line]]), 'local utils = require("senp')
  child.lua("assistant:process_chunk(...)", { 'ai.usecase.utils")' })
  child.lua("assistant:process_chunk(...)", { "\n\nlocal M = {}\n" })
  child.lua("assistant:process_chunk(...)", { "\n</search>\n<replace>" })
  eq(
    Helpers.get_line(child, bufnr, -2),
    "filepath: lua/senpai/usecase/message/tool_call.lua"
  )
  child.lua(
    "assistant:process_chunk(...)",
    { '\nlocal utils = require("senpai.use' }
  )
  eq(Helpers.get_line(child, bufnr, -2), "```lua")
  eq(Helpers.get_line(child, bufnr, -1), 'local utils = require("senpai.use')
  child.lua(
    "assistant:process_chunk(...)",
    { 'case.utils")\n\n---@class ToolCall' }
  )
  child.lua("assistant:process_chunk(...)", { "Module\nlocal M = {}\n" })
  child.lua(
    "assistant:process_chunk(...)",
    { "\n</replace>\n</replace_file>\n\nhello" }
  )
  eq(Helpers.get_line(child, bufnr, -7), "local M = {}")
  eq(Helpers.get_line(child, bufnr, -6), "")
  eq(Helpers.get_line(child, bufnr, -5), "```")
  eq(Helpers.get_line(child, bufnr, -4), "")
  eq(Helpers.get_line(child, bufnr, -3), "</SenpaiReplaceFile>")
  eq(Helpers.get_line(child, bufnr, -2), "")
  eq(Helpers.get_line(child, bufnr, -1), "hello")
  expect.reference_screenshot(child.get_screenshot())
  local result = child.lua_get("chat.replace_file_results")
  local count = 0

  for id, content in pairs(result) do
    eq(type(id), "string")
    eq(content.path, "lua/senpai/usecase/message/tool_call.lua")
    eq(content.search, {
      'local utils = require("senpai.usecase.utils")',
      "",
      "local M = {}",
      "",
    })
    eq(content.replace, {
      'local utils = require("senpai.usecase.utils")',
      "",
      "---@class ToolCallModule",
      "local M = {}",
      "",
    })
    count = count + 1
  end
  eq(count, 1)
end

T["assistant <replace_file> from message"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_assistant" } }
  )
  child.lua([[chat:show()]])
  child.lua("assistant=M.new(chat)")
  child.lua("assistant:process_chunk(...)", {
    [[
plain text here.
<replace_file>
<path>src/main.js</path>
<search>
  return a - b;
</search>
<replace>
  return a + b;
</replace>
</replace_file>

example foo bar.
  ]],
  })
  local result = child.lua_get("chat.replace_file_results")
  local count = 0

  for id, content in pairs(result) do
    eq(type(id), "string")
    eq(content.path, "src/main.js")
    eq(content.search, { "  return a - b;" })
    eq(content.replace, { "  return a + b;" })
    count = count + 1
  end
  eq(count, 1)

  local bufnr = child.lua_get([[chat.log_area.bufnr]])
  eq(Helpers.get_line(child, bufnr, 5), "---")
  eq(Helpers.get_line(child, bufnr, 6), "plain text here.")
  eq(Helpers.get_line(child, bufnr, 7), "")
  eq(
    Helpers.get_line(child, bufnr, 8):find([[<SenpaiReplaceFile id=".*">]])
      ~= nil,
    true
  )
  eq(Helpers.get_line(child, bufnr, 9), "")
  eq(Helpers.get_line(child, bufnr, 10), "filepath: src/main.js")
  eq(Helpers.get_line(child, bufnr, 11), "```javascript")
  eq(Helpers.get_line(child, bufnr, 12), "  return a + b;")
  eq(Helpers.get_line(child, bufnr, 13), "```")
  eq(Helpers.get_line(child, bufnr, 14), "")
  eq(Helpers.get_line(child, bufnr, 15), "</SenpaiReplaceFile>")
  eq(Helpers.get_line(child, bufnr, 16), "")
  eq(Helpers.get_line(child, bufnr, 17), "example foo bar.")
end

T["assistant two newline"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_assistant" } }
  )
  child.lua([[chat:show()]])
  local bufnr = child.lua_get([[chat.log_area.bufnr]])
  child.lua("assistant=M.new(chat)")
  eq(Helpers.get_line(child, bufnr, 5), "---")

  child.lua("assistant:process_chunk(...)", { "plain text \n\n" })
  eq(Helpers.get_line(child, bufnr, 6), "plain text ")
  eq(Helpers.get_line(child, bufnr, 7), "")
  eq(Helpers.get_line(child, bufnr, 8), "")
  eq(Helpers.get_line(child, bufnr, 9), nil)
end

T["assistant <replace_file> xml"] = function()
  -- for screenshot
  child.o.lines, child.o.columns = 40, 60

  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_assistant" } }
  )
  child.lua([[chat:show()]])
  child.cmd("1windo close")
  local bufnr = child.lua_get([[chat.log_area.bufnr]])
  child.lua("assistant=M.new(chat)")
  eq(Helpers.get_line(child, bufnr, 5), "---")

  child.lua("assistant:process_chunk(...)", { "here:\n\n<replace_" })
  child.lua("assistant:process_chunk(...)", { "file>\n<path>lua" })
  eq(
    Helpers.get_line(child, bufnr, -3):find([[<SenpaiReplaceFile id=".*">]])
      ~= nil,
    true
  )
  child.lua("assistant:process_chunk(...)", { "/senpai/usecase/message/" })
  child.lua("assistant:process_chunk(...)", { "tool_call.lua</path>" })
  eq(
    child.lua_get([[assistant.line]]),
    "<path>lua/senpai/usecase/message/tool_call.lua</path>"
  )
  child.lua(
    "assistant:process_chunk(...)",
    { '\n<search>\nlocal utils = require("senp' }
  )
  eq(Helpers.get_line(child, bufnr, -3), "")
  eq(
    Helpers.get_line(child, bufnr, -2),
    "filepath: lua/senpai/usecase/message/tool_call.lua"
  )
  eq(Helpers.get_line(child, bufnr, -1), "")
  eq(child.lua_get([[assistant.line]]), 'local utils = require("senp')
  child.lua("assistant:process_chunk(...)", { 'ai.usecase.utils")' })
  child.lua("assistant:process_chunk(...)", { "\n\nlocal M = {}\n" })
  child.lua("assistant:process_chunk(...)", { "\n</search" })
  child.lua("assistant:process_chunk(...)", { ">\n<replace>" })
  eq(
    Helpers.get_line(child, bufnr, -2),
    "filepath: lua/senpai/usecase/message/tool_call.lua"
  )
  child.lua(
    "assistant:process_chunk(...)",
    { '\nlocal utils = require("senpai.use' }
  )
  eq(Helpers.get_line(child, bufnr, -2), "```lua")
  eq(Helpers.get_line(child, bufnr, -1), 'local utils = require("senpai.use')
  child.lua(
    "assistant:process_chunk(...)",
    { 'case.utils")\n\n---@class ToolCall' }
  )
  child.lua("assistant:process_chunk(...)", { "Module\nlocal M = {}\n" })
  child.lua(
    "assistant:process_chunk(...)",
    { "\n</replace>\n</replace_file>\n\nhello" }
  )
  eq(Helpers.get_line(child, bufnr, -7), "local M = {}")
  eq(Helpers.get_line(child, bufnr, -6), "")
  eq(Helpers.get_line(child, bufnr, -5), "```")
  eq(Helpers.get_line(child, bufnr, -4), "")
  eq(Helpers.get_line(child, bufnr, -3), "</SenpaiReplaceFile>")
  eq(Helpers.get_line(child, bufnr, -2), "")
  eq(Helpers.get_line(child, bufnr, -1), "hello")
  expect.reference_screenshot(child.get_screenshot())
  local result = child.lua_get("chat.replace_file_results")
  local count = 0

  for id, content in pairs(result) do
    eq(type(id), "string")
    eq(content.path, "lua/senpai/usecase/message/tool_call.lua")
    eq(content.search, {
      'local utils = require("senpai.usecase.utils")',
      "",
      "local M = {}",
      "",
    })
    eq(content.replace, {
      'local utils = require("senpai.usecase.utils")',
      "",
      "---@class ToolCallModule",
      "local M = {}",
      "",
    })
    count = count + 1
  end
  eq(count, 1)
end

return T
