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

T["assistant <replace_file> from chunk"] = function()
  child.lua([[chat=require("senpai.presentation.chat.window").new({})]])
  child.lua("assistant=M.new(chat)")
  child.lua("assistant:process_chunk(...)", { "plain text " })
  child.lua("assistant:process_chunk(...)", { "here.\n" })
  child.lua("assistant:process_chunk(...)", { "<replace_file>\n<path>src/m" })
  child.lua("assistant:process_chunk(...)", { "ain.js</path>\n" })
  child.lua(
    "assistant:process_chunk(...)",
    { "<search>\n  return a - b;\n</search>\n" }
  )
  child.lua(
    "assistant:process_chunk(...)",
    { "<replace>\n  return a + b;\n</replace>\n" }
  )
  child.lua("assistant:process_chunk(...)", { "</replace_file>\nexam" })
  child.lua("assistant:process_chunk(...)", { "ple foo bar.\n" })

  local result = child.lua_get("assistant.replace_file_table")
  local count = 0

  for _, content in pairs(result) do
    eq(content.path, "src/main.js")
    eq(content.search, { "  return a - b;" })
    eq(content.replace, { "  return a + b;" })
    count = count + 1
  end
  eq(count, 1)
end

T["assistant <replace_file> from message"] = function()
  child.lua([[chat=require("senpai.presentation.chat.window").new({})]])
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
  local result = child.lua_get("assistant.replace_file_table")
  local count = 0

  for _, content in pairs(result) do
    eq(content.path, "src/main.js")
    eq(content.search, { "  return a - b;" })
    eq(content.replace, { "  return a + b;" })
    count = count + 1
  end
  eq(count, 1)
end

return T
