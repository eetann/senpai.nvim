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

T["<execute_command>"]["from message"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_assistant" } }
  )
  child.lua([[chat:show()]])
  child.lua("assistant=M.new(chat)")
  child.lua("assistant:process_chunk(...)", {
    [[
plain text here.
<execute_command>
<command>mv foo.js bar.js</command>
</execute_command>

example foo bar.
  ]],
  })
  eq(
    child.lua_get("chat.sticky_popup_manager.popups[7].command"),
    "mv foo.js bar.js"
  )

  local bufnr = child.lua_get([[chat.log_area.bufnr]])
  eq(child.get_line(bufnr, 5), "---")
  eq(child.get_line(bufnr, 6), "plain text here.")
  eq(child.get_line(bufnr, 7), "")
  eq(child.get_line(bufnr, 8), "```sh")
  eq(child.get_line(bufnr, 9), "mv foo.js bar.js")
  eq(child.get_line(bufnr, 10), "```")
end

T["<execute_command>"]["Line breaks in the middle of tags"] = function()
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

  child.lua("assistant:process_chunk(...)", { "here:\n\n<execute_" })
  child.lua("assistant:process_chunk(...)", { "command>\n<command>mv " })
  child.lua("assistant:process_chunk(...)", { "foo.js " })
  child.lua("assistant:process_chunk(...)", { "bar.js</command>" })
  eq(child.lua_get([[assistant.line]]), "<command>mv foo.js bar.js</command>")
  child.lua("assistant:process_chunk(...)", { "\n</execute_command>\n\nhello" })
  eq(
    child.lua_get("chat.sticky_popup_manager.popups[8].command"),
    "mv foo.js bar.js"
  )
  eq(child.get_line(bufnr, -2), "")
  eq(child.get_line(bufnr, -1), "hello")
  expect.reference_screenshot(child.get_screenshot())
end

T["<execute_command>"]["end tag"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_assistant" } }
  )
  child.lua([[chat:show()]])
  child.lua("assistant=M.new(chat)")
  child.lua("assistant:process_chunk(...)", {
    [[
plain text here.
<execute_command>
<command>mv foo.js bar.js</command>
</execute_command>]],
  })

  eq(
    child.lua_get("chat.sticky_popup_manager.popups[7].command"),
    "mv foo.js bar.js"
  )
end

return T
