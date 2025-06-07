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

  -- Verify the tool block was rendered correctly
  -- The block should create a popup with the question and suggestions
  local popup_count = child.lua_get([[#chat.sticky_popup_manager.popups]])
  expect.equality(popup_count, 1)
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

  -- Verify the tool block was still rendered even with empty followUp
  local popups = child.lua_get([[chat.sticky_popup_manager.popups]])
  expect.equality(type(popups), "table")

  local popup_count = 0
  for _ in pairs(popups) do
    popup_count = popup_count + 1
  end
  expect.equality(popup_count, 1)
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

  -- Get the first (and only) popup block
  local first_popup = child.lua([[
    local popups = chat.sticky_popup_manager.popups
    for _, popup in pairs(popups) do
      return {
        block_type = popup.block_type,
        question = popup.question,
        followUp = popup.followUp,
      }
    end
  ]])

  expect.equality(type(first_popup), "table")
  expect.equality(first_popup.block_type, "ask_followup_question")
  expect.equality(first_popup.question, "Which option?")
  expect.equality(#first_popup.followUp, 2)
  expect.equality(first_popup.followUp[1], "Option A")
  expect.equality(first_popup.followUp[2], "Option B")

  -- Test action buttons generation
  local action_buttons = child.lua([[
    local popups = chat.sticky_popup_manager.popups
    for _, popup in pairs(popups) do
      return popup:get_action_buttons()
    end
  ]])

  expect.equality(type(action_buttons), "table")
  -- Should have: 2 suggestions + Custom + Dismiss = 4 buttons
  expect.equality(#action_buttons, 4)

  -- Check the first two buttons are the suggestions
  expect.equality(action_buttons[1].key, "1")
  expect.equality(action_buttons[1].label, "Option A")
  expect.equality(action_buttons[2].key, "2")
  expect.equality(action_buttons[2].label, "Option B")

  -- Check Custom and Dismiss buttons
  expect.equality(action_buttons[3].key, "c")
  expect.equality(action_buttons[3].label, "Custom")
  expect.equality(action_buttons[4].key, "d")
  expect.equality(action_buttons[4].label, "Dismiss")
end

return T

