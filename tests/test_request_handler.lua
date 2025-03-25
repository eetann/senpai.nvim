local Helpers = dofile("tests/helpers.lua")
local child = Helpers.new_child_neovim()
local expect, eq = Helpers.expect, Helpers.expect.equality

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.load()
      child.lua([[M = require('senpai.usecase.request.request_handler')]])
    end,
    post_once = child.stop,
  },
})

T["parse_stream_part()"] = MiniTest.new_set()

T["parse_stream_part()"]["Correctly formatted text parts can be parsed."] = function()
  local result =
    child.lua([[return M.parse_stream_part(...)]], { '0:"example\nfoo"' })
  eq(result.type, "0")
  eq(result.content, "example\nfoo")
end

T["parse_stream_part()"]["Correctly formatted data parts can be parsed."] = function()
  local result = child.lua(
    [[return M.parse_stream_part(...)]],
    { '2:[{"key":"object1"},{"anotherKey":"object2"}]' }
  )
  eq(result.type, "2")
  eq(#result.content, 2)
  eq(result.content[1].key, "object1")
  eq(result.content[2].anotherKey, "object2")
end

T["parse_stream_part()"]["Correctly formatted tool parts can be parsed."] = function()
  local result = child.lua([[return M.parse_stream_part(...)]], {
    '9:{"toolCallId":"call-123","toolName":"my-tool","args":{"some":"argument"}}',
  })
  eq(result.type, "9")
  eq(result.content.toolCallId, "call-123")
  eq(result.content.toolName, "my-tool")
  eq(result.content.args.some, "argument")
end

T["parse_stream_part()"]["Returns invalid results in case of bad format"] = function()
  local result =
    child.lua([[return M.parse_stream_part(...)]], { "invalid format" })
  eq(result.type, nil)
  eq(result.content, "")
end

T["parse_stream_part()"]["Handle errors if JSON is invalid."] = function()
  local result =
    child.lua([[return M.parse_stream_part(...)]], { '0:{"invalid json' })
  eq(result.type, nil)
  eq(type(result.content), "string")
end

T["parse_stream_part()"][" various types of stream parts"] = function()
  local reasoning = child.lua(
    [[return M.parse_stream_part(...)]],
    { 'g:"I will open the conversation with witty banter."' }
  )
  eq(reasoning.type, "g")
  eq(reasoning.content, "I will open the conversation with witty banter.")

  local error_part =
    child.lua([[return M.parse_stream_part(...)]], { '3:"error message"' })
  eq(error_part.type, "3")
  eq(error_part.content, "error message")

  local finish = child.lua([[return M.parse_stream_part(...)]], {
    'd:{"finishReason":"stop","usage":{"promptTokens":10,"completionTokens":20}}',
  })
  eq(finish.type, "d")
  eq(finish.content.finishReason, "stop")
  eq(finish.content.usage.promptTokens, 10)
  eq(finish.content.usage.completionTokens, 20)
end

return T
