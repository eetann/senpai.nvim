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

T["assistant"] = MiniTest.new_set()

T["assistant"]["<replace_file> chunk process"] = function()
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
  eq(child.get_line(bufnr, 9), "")
  eq(child.get_line(bufnr, 10), "")

  local replace_buf = child.lua_get([[assistant.diff_popup.tabs.replace.bufnr]])
  eq(child.get_lines(replace_buf), { "  return a + b;" })
  sleep(500)
  eq(
    child.api.nvim_get_option_value("filetype", { buf = replace_buf }),
    "javascript"
  )

  local search_buf = child.lua_get([[assistant.diff_popup.tabs.search.bufnr]])
  eq(child.get_lines(search_buf), { "  return a - b;" })

  child.lua("assistant:process_chunk(...)", { "red\nblue" })
  child.lua("assistant:process_chunk(...)", { " yellow green" })
  eq(child.get_line(bufnr, 9), "")
  eq(child.get_line(bufnr, 10), "red")
  eq(child.get_line(bufnr, 11), "blue yellow green")
  eq(child.get_line(bufnr, 12), nil)
end

T["assistant"]["<replace_file> real"] = function()
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
    child.get_line(bufnr, -3),
    "filepath: lua/senpai/usecase/message/tool_call.lua"
  )
  eq(child.lua_get([=[assistant.diff_popup.renderer.layout._.mounted]=]), true)
  eq(child.get_line(bufnr, -2), "")
  eq(child.get_line(bufnr, -1), "")
  eq(child.lua_get([[assistant.line]]), 'local utils = require("senp')
  child.lua("assistant:process_chunk(...)", { 'ai.usecase.utils")' })
  child.lua("assistant:process_chunk(...)", { "\n\nlocal M = {}\n" })
  child.lua("assistant:process_chunk(...)", { "\n</search>\n<replace>" })
  eq(
    child.get_line(bufnr, -3),
    "filepath: lua/senpai/usecase/message/tool_call.lua"
  )
  child.lua(
    "assistant:process_chunk(...)",
    { '\nlocal utils = require("senpai.use' }
  )
  local replace_buf = child.lua_get([[assistant.diff_popup.tabs.replace.bufnr]])
  eq(child.get_lines(replace_buf), { "" })
  child.lua(
    "assistant:process_chunk(...)",
    { 'case.utils")\n\n---@class ToolCall' }
  )
  eq(
    child.get_lines(replace_buf),
    { [[local utils = require("senpai.usecase.utils")]], "", "" }
  )
  child.lua("assistant:process_chunk(...)", { "Module\nlocal M = {}\n" })
  child.lua(
    "assistant:process_chunk(...)",
    { "\n</replace>\n</replace_file>\n\nhello" }
  )
  eq(
    child.get_lines(replace_buf),
    vim.split(
      [[
local utils = require("senpai.usecase.utils")

---@class ToolCallModule
local M = {}
]],
      "\n"
    )
  )
  sleep(500)
  eq(child.api.nvim_get_option_value("filetype", { buf = replace_buf }), "lua")

  local search_buf = child.lua_get([[assistant.diff_popup.tabs.search.bufnr]])
  eq(
    child.get_lines(search_buf),
    vim.split(
      [[
local utils = require("senpai.usecase.utils")

local M = {}
]],
      "\n"
    )
  )
  eq(child.get_line(bufnr, -2), "")
  eq(child.get_line(bufnr, -1), "hello")
  child.lua([[assistant.diff_popup:focus()]])
  eq(
    child.api.nvim_get_current_buf(),
    child.lua_get([[assistant.diff_popup.tabs.replace.bufnr]])
  )
  eq(child.get_line(0, 1), 'local utils = require("senpai.usecase.utils")')

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

T["assistant"]["<replace_file> from message"] = function()
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
  eq(child.get_line(bufnr, 5), "---")
  eq(child.get_line(bufnr, 6), "plain text here.")
  eq(child.get_line(bufnr, 7), "")
  eq(child.get_line(bufnr, 8), "filepath: src/main.js")

  local replace_buf = child.lua_get([[assistant.diff_popup.tabs.replace.bufnr]])
  eq(child.get_lines(replace_buf), { "  return a + b;" })
  local search_buf = child.lua_get([[assistant.diff_popup.tabs.search.bufnr]])
  eq(child.get_lines(search_buf), { "  return a - b;" })
  eq(child.get_line(bufnr, 9), "")
  eq(child.get_line(bufnr, 10), "")
  eq(child.get_line(bufnr, 11), "example foo bar.")
end

T["assistant two newline"] = function()
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

T["assistant"]["<replace_file> Line breaks in the middle of tags"] = function()
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
  eq(child.get_line(bufnr, -4), "")
  eq(
    child.get_line(bufnr, -3),
    "filepath: lua/senpai/usecase/message/tool_call.lua"
  )
  eq(child.get_line(bufnr, -2), "")
  eq(child.get_line(bufnr, -1), "")
  eq(child.lua_get([[assistant.line]]), 'local utils = require("senp')
  child.lua("assistant:process_chunk(...)", { 'ai.usecase.utils")' })
  child.lua("assistant:process_chunk(...)", { "\n\nlocal M = {}\n" })
  child.lua("assistant:process_chunk(...)", { "\n</search" })
  child.lua("assistant:process_chunk(...)", { ">\n<replace>" })
  child.lua("assistant:process_chunk(...)", { "\nlocal M = {}\n" })
  child.lua("assistant:process_chunk(...)", { "\n</replace" })
  child.lua("assistant:process_chunk(...)", { ">\n</replace_file>\n\nhello" })
  local replace_buf = child.lua_get([[assistant.diff_popup.tabs.replace.bufnr]])
  eq(child.get_lines(replace_buf), { "local M = {}", "" })
  local search_buf = child.lua_get([[assistant.diff_popup.tabs.search.bufnr]])
  eq(
    child.get_lines(search_buf),
    vim.split(
      [[
local utils = require("senpai.usecase.utils")

local M = {}
]],
      "\n"
    )
  )
  eq(child.get_line(bufnr, -2), "")
  eq(child.get_line(bufnr, -1), "hello")
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
    eq(content.replace, { "local M = {}", "" })
    count = count + 1
  end
  eq(count, 1)
end

T["assistant"]["end with <replace_file>"] = function()
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
  eq(child.get_line(bufnr, -5), "plain text here.")
  eq(child.get_line(bufnr, -4), "")
  eq(child.get_line(bufnr, -3), "filepath: src/main.js")
  eq(child.get_line(bufnr, -2), "")
  eq(child.get_line(bufnr, -1), "")
end

return T
