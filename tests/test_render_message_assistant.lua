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
  local bufnr = child.lua_get([[chat.chat_log.bufnr]])
  child.lua("assistant=M.new(chat)")
  eq(Helpers.get_line(child, bufnr, 5), "---")

  child.lua("assistant:process_chunk(...)", { "plain text " })
  eq(child.lua_get("assistant.chunks"), "plain text ")
  eq(Helpers.get_line(child, bufnr, 6), "plain text ")
  child.lua("assistant:process_chunk(...)", { "here.\n" })
  -- TODO:
  eq(Helpers.get_all_line(child, bufnr), "plain text here.")
  eq(Helpers.get_line(child, bufnr, 6), "plain text here.")
  eq(child.lua_get("assistant.chunks"), "")

  child.lua("assistant:process_chunk(...)", { "<replace" })
  eq(Helpers.get_line(child, bufnr, 6), "plain text here.")
  eq(Helpers.get_line(child, bufnr, 7), "<replace")
  eq(child.lua_get("assistant.chunks"), "<replace")
  child.lua("assistant:process_chunk(...)", { "_file>\n" })

  local buf_content = child.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  eq(buf_content[7], "")
  eq(buf_content[8]:find([[<SenpaiReplaceFile id=".*">]]) ~= nil, true)
  eq(buf_content[9], "")
  eq(buf_content[10], "")
end

-- T["assistant <replace_file> from chunk"] = function()
--   child.lua([[chat=require("senpai.presentation.chat.window").new({})]])
--   child.lua([[chat:show()]])
--   child.lua("assistant=M.new(chat)")
--   child.lua("assistant:process_chunk(...)", { "plain text " })
--   child.lua("assistant:process_chunk(...)", { "here.\n" })
--   child.lua("assistant:process_chunk(...)", { "<replace_file>\n<path>src/m" })
--   child.lua("assistant:process_chunk(...)", { "ain.js</path>\n" })
--   child.lua(
--     "assistant:process_chunk(...)",
--     { "<search>\n  return a - b;\n</search>\n" }
--   )
--   child.lua(
--     "assistant:process_chunk(...)",
--     { "<replace>\n  return a + b;\n</replace>\n" }
--   )
--   child.lua("assistant:process_chunk(...)", { "</replace_file>\nexam" })
--   child.lua("assistant:process_chunk(...)", { "ple foo bar.\n" })
--
--   local result = child.lua_get("chat.replace_file_results")
--   local count = 0
--
--   for _, content in pairs(result) do
--     eq(content.path, "src/main.js")
--     eq(content.search, { "  return a - b;" })
--     eq(content.replace, { "  return a + b;" })
--     count = count + 1
--   end
--   eq(count, 1)
-- end

-- T["assistant <replace_file> from message"] = function()
--   child.lua([[chat=require("senpai.presentation.chat.window").new({})]])
--   child.lua([[chat:show()]])
--   child.lua("assistant=M.new(chat)")
--   child.lua("assistant:process_chunk(...)", {
--     [[
-- plain text here.
-- <replace_file>
-- <path>src/main.js</path>
-- <search>
--   return a - b;
-- </search>
-- <replace>
--   return a + b;
-- </replace>
-- </replace_file>
-- example foo bar.
--   ]],
--   })
--   local result = child.lua_get("chat.replace_file_results")
--   local count = 0
--
--   for id, content in pairs(result) do
--     eq(type(id), "string")
--     eq(content.path, "src/main.js")
--     eq(content.search, { "  return a - b;" })
--     eq(content.replace, { "  return a + b;" })
--     count = count + 1
--   end
--   eq(count, 1)
--
--   local bufnr = child.lua_get([[chat.chat_log.bufnr]])
--   local buf_content = child.api.nvim_buf_get_lines(bufnr, 0, -1, false)
--   eq(buf_content[5], "---")
--   eq(buf_content[6], "plain text here.")
--   eq(buf_content[7]:find([[<SenpaiReplaceFile id=".*">]]) ~= nil, true)
--   eq(buf_content[8], "filepath: src/main.js")
--   eq(buf_content[9], "```javascript")
--   eq(buf_content[10], "  return a + b;")
--   eq(buf_content[11], "```")
--   eq(buf_content[12], "</SenpaiReplaceFile>")
--   eq(buf_content[13], "example foo bar.")
-- end

return T
