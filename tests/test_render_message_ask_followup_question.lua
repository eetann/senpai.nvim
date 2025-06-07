local Helpers = dofile("tests/helpers.lua")
local child = Helpers.new_child_neovim()
local expect, eq = Helpers.expect, Helpers.expect.equality

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.lua([[M=require("senpai.usecase.message.assistant")]])
    end,
    post_once = child.stop,
  },
})

T["<ask_followup_question>"] = MiniTest.new_set()

T["tool_result: AskFollowupQuestion block is rendered"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_ask_followup_question" } }
  )
  child.lua([[chat:show()]])
  local bufnr = child.lua_get([[chat.log_area.bufnr]])

  local tool_result_part = {
    toolCallId = "AskFollowupQuestion-2025-01-01",
    toolName = "AskFollowupQuestion",
    result = {
      question = "What is the path to the config file?",
      followUp = {
        "./src/config.json",
        "./config/settings.json",
        "./config.json",
      },
    },
  }
  child.lua(
    'require("senpai.usecase.message.tool_result").render_from_memory(chat, ...)',
    { tool_result_part }
  )
  child.lua([[
    chat:show_action_buttons()
  ]])

  -- Verify the tool blocks were rendered correctly
  -- Should create one block for each suggestion (3 suggestions = 3 blocks)
  local popup_count = child.lua_get([[
    local count = 0
    for _ in pairs(chat.sticky_popup_manager.popups) do
      count = count + 1
    end
    return count
  ]])
  expect.equality(popup_count, 3)
end

T["tool_result: AskFollowupQuestion with empty follow-up"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_ask_followup_question_empty" } }
  )
  child.lua([[chat:show()]])

  local tool_result_part = {
    toolCallId = "AskFollowupQuestion-2025-01-01",
    toolName = "AskFollowupQuestion",
    result = {
      question = "Should we proceed?",
      followUp = {},
    },
  }
  child.lua(
    'require("senpai.usecase.message.tool_result").render_from_memory(chat, ...)',
    { tool_result_part }
  )

  -- Verify no blocks are created with empty followUp
  local popup_count = child.lua_get([[
    local count = 0
    for _ in pairs(chat.sticky_popup_manager.popups) do
      count = count + 1
    end
    return count
  ]])
  expect.equality(popup_count, 0)
end

T["tool_result: AskFollowupQuestion action buttons are generated"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_ask_followup_question_buttons" } }
  )
  child.lua([[chat:show()]])

  local tool_result_part = {
    toolCallId = "AskFollowupQuestion-2025-01-01",
    toolName = "AskFollowupQuestion",
    result = {
      question = "Which option?",
      followUp = {
        "Option A",
        "Option B",
      },
    },
  }
  child.lua(
    'require("senpai.usecase.message.tool_result").render_from_memory(chat, ...)',
    { tool_result_part }
  )

  -- Should create 2 blocks for 2 suggestions
  local popup_count = child.lua_get([[
    local count = 0
    for _ in pairs(chat.sticky_popup_manager.popups) do
      count = count + 1
    end
    return count
  ]])
  expect.equality(popup_count, 2)

  -- Get all popup blocks and verify their suggestions
  local suggestions = child.lua([[
    local suggestions = {}
    for _, popup in pairs(chat.sticky_popup_manager.popups) do
      if popup.block_type == "ask_followup_question" then
        table.insert(suggestions, popup.suggestion)
      end
    end
    table.sort(suggestions) -- Sort for consistent testing
    return suggestions
  ]])

  expect.equality(type(suggestions), "table")
  expect.equality(#suggestions, 2)
  expect.equality(suggestions[1], "Option A")
  expect.equality(suggestions[2], "Option B")
end

return T

