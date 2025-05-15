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

T["<replace_file>"] = MiniTest.new_set()

T["<replace_file>"]["chunk process"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_assistant" } }
  )
  child.lua([[chat:show()]])
  local bufnr = child.lua_get([[chat.log_area.bufnr]])
  child.lua("assistant=M.new(chat)")
  eq(child.get_line(bufnr, 5), "---")

  child.lua("assistant:process_chunk(...)", { "plain text " })
  eq(child.get_line(bufnr, 6), "plain text ")
  eq(child.get_line(bufnr, 7), nil)
  child.lua("assistant:process_chunk(...)", { "here.\n" })
  eq(child.get_line(bufnr, 6), "plain text here.")
  eq(child.get_line(bufnr, 7), "")
  eq(child.get_line(bufnr, 8), nil)

  child.lua("assistant:process_chunk(...)", { "<replace" })
  eq(child.get_line(bufnr, 6), "plain text here.")
  eq(child.get_line(bufnr, 7), "<replace")
  child.lua("assistant:process_chunk(...)", { "_file>\n" })
  eq(child.get_line(bufnr, 7), "")
  eq(child.get_line(bufnr, 8), "")
  eq(child.get_line(bufnr, 9), nil)

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
  eq(child.get_line(bufnr, 8), "filepath: src/main.js")
  eq(child.get_line(bufnr, 9), "```diff")
  eq(child.get_line(bufnr, 10), "-  return a - b;")
  eq(child.get_line(bufnr, 12), "+  return a + b;")
  eq(child.get_line(bufnr, 15), "```")
  child.lua("assistant:process_chunk(...)", { "red\nblue" })
  child.lua("assistant:process_chunk(...)", { " yellow green" })
  eq(child.get_line(bufnr, 16), "red")
  eq(child.get_line(bufnr, 17), "blue yellow green")
  eq(child.get_line(bufnr, 18), nil)
end

T["<replace_file>"]["real"] = function()
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
  eq(child.get_line(bufnr, 5), "---")

  child.lua("assistant:process_chunk(...)", { "here:\n\n<replace_" })
  child.lua("assistant:process_chunk(...)", { "file>\n<path>lua" })
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
  eq(
    child.get_line(bufnr, -2),
    "filepath: lua/senpai/usecase/message/tool_call.lua"
  )
  eq(
    child.lua_get(
      [=[assistant.tag_handlers[assistant.current_tag].diff_popup.renderer.layout._.mounted]=]
    ),
    true
  )
  eq(child.get_line(bufnr, -1), "")
  eq(child.lua_get([[assistant.line]]), 'local utils = require("senp')
  child.lua("assistant:process_chunk(...)", { 'ai.usecase.utils")' })
  child.lua("assistant:process_chunk(...)", { "\n\nlocal M = {}\n" })
  child.lua("assistant:process_chunk(...)", { "\n</search>\n<replace>" })
  eq(
    child.get_line(bufnr, -2),
    "filepath: lua/senpai/usecase/message/tool_call.lua"
  )
  child.lua(
    "assistant:process_chunk(...)",
    { '\nlocal utils = require("senpai.use' }
  )
  child.lua(
    [[_G.current_diff_popup = assistant.tag_handlers[assistant.current_tag].diff_popup]]
  )
  eq(child.lua_get([[_G.current_diff_popup.replace_text]]), "")

  child.lua(
    "assistant:process_chunk(...)",
    { 'case.utils")\n\n---@class ToolCall' }
  )

  child.lua("assistant:process_chunk(...)", { "Module\nlocal M = {}\n" })
  child.lua(
    "assistant:process_chunk(...)",
    { "\n</replace>\n</replace_file>\n\nhello" }
  )
  eq(
    child.lua_get([[_G.current_diff_popup.replace_text]]),
    [[
local utils = require("senpai.usecase.utils")

---@class ToolCallModule
local M = {}
]]
  )

  eq(
    child.lua_get([[_G.current_diff_popup.search_text]]),
    [[
local utils = require("senpai.usecase.utils")

local M = {}
]]
  )
  eq(child.get_line(bufnr, -2), "")
  eq(child.get_line(bufnr, -1), "hello")

  eq(
    child.lua_get("chat.sticky_popup_manager.popups[9].path"),
    "lua/senpai/usecase/message/tool_call.lua"
  )
  eq(
    child.lua_get("chat.sticky_popup_manager.popups[9].search_text"),
    [[
local utils = require("senpai.usecase.utils")

local M = {}
]]
  )
  eq(
    child.lua_get("chat.sticky_popup_manager.popups[9].replace_text"),
    [[
local utils = require("senpai.usecase.utils")

---@class ToolCallModule
local M = {}
]]
  )
end

T["<replace_file>"]["from message"] = function()
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
  eq(child.lua_get("chat.sticky_popup_manager.popups[8].path"), "src/main.js")
  eq(
    child.lua_get("chat.sticky_popup_manager.popups[8].search_text"),
    "  return a - b;"
  )
  eq(
    child.lua_get("chat.sticky_popup_manager.popups[8].replace_text"),
    "  return a + b;"
  )

  local bufnr = child.lua_get([[chat.log_area.bufnr]])
  eq(child.get_line(bufnr, 5), "---")
  eq(child.get_line(bufnr, 6), "plain text here.")
  eq(child.get_line(bufnr, 7), "")
  eq(child.get_line(bufnr, 8), "filepath: src/main.js")
end

T["<replace_file>"]["two newline"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_assistant" } }
  )
  child.lua([[chat:show()]])
  local bufnr = child.lua_get([[chat.log_area.bufnr]])
  child.lua("assistant=M.new(chat)")
  eq(child.get_line(bufnr, 5), "---")

  child.lua("assistant:process_chunk(...)", { "plain text \n\n" })
  eq(child.get_line(bufnr, 6), "plain text ")
  eq(child.get_line(bufnr, 7), "")
  eq(child.get_line(bufnr, 8), "")
  eq(child.get_line(bufnr, 9), nil)
end

T["<replace_file>"]["Line breaks in the middle of tags"] = function()
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
  eq(child.get_line(bufnr, 5), "---")

  child.lua("assistant:process_chunk(...)", { "here:\n\n<replace_" })
  child.lua("assistant:process_chunk(...)", { "file>\n<path>lua" })
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
  eq(child.get_line(bufnr, -3), "")
  eq(
    child.get_line(bufnr, -2),
    "filepath: lua/senpai/usecase/message/tool_call.lua"
  )
  eq(child.get_line(bufnr, -1), "")
  eq(child.lua_get([[assistant.line]]), 'local utils = require("senp')
  child.lua("assistant:process_chunk(...)", { 'ai.usecase.utils")' })
  child.lua("assistant:process_chunk(...)", { "\n\nlocal M = {}\n" })
  child.lua("assistant:process_chunk(...)", { "\n</search" })
  child.lua("assistant:process_chunk(...)", { ">\n<replace>" })
  child.lua("assistant:process_chunk(...)", { "\nlocal M = {}\n" })
  child.lua("assistant:process_chunk(...)", { "\n</replace" })
  child.lua("assistant:process_chunk(...)", { ">\n</replace_file>\n\nhello" })
  eq(child.get_line(bufnr, -2), "")
  eq(child.get_line(bufnr, -1), "hello")
  expect.reference_screenshot(child.get_screenshot())
  eq(
    child.lua_get("chat.sticky_popup_manager.popups[9].path"),
    "lua/senpai/usecase/message/tool_call.lua"
  )
  eq(
    child.lua_get("chat.sticky_popup_manager.popups[9].search_text"),
    [[
local utils = require("senpai.usecase.utils")

local M = {}
]]
  )
  eq(
    child.lua_get("chat.sticky_popup_manager.popups[9].replace_text"),
    "local M = {}\n"
  )
end

T["<replace_file>"]["end tag"] = function()
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
</replace_file>]],
  })

  eq(child.lua_get("chat.sticky_popup_manager.popups[8].path"), "src/main.js")
  eq(
    child.lua_get("chat.sticky_popup_manager.popups[8].search_text"),
    "  return a - b;"
  )
  eq(
    child.lua_get("chat.sticky_popup_manager.popups[8].replace_text"),
    "  return a + b;"
  )
end

return T
