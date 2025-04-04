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
  child.lua([[chat=require("senpai.presentation.chat.window").new({})]])
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
  eq(Helpers.get_line(child, bufnr, 16), "")
  eq(Helpers.get_line(child, bufnr, 17), "red")
  eq(Helpers.get_line(child, bufnr, 18), "blue yellow green")
  eq(Helpers.get_line(child, bufnr, 19), nil)
end

T["assistant <replace_file> from message"] = function()
  child.lua([[chat=require("senpai.presentation.chat.window").new({})]])
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
  child.lua([[chat=require("senpai.presentation.chat.window").new({})]])
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

return T
