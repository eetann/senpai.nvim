local Spinner = require("senpai.presentation.shared.spinner")
local RequestHandler = require("senpai.presentation.shared.request_handler")
local utils = require("senpai.usecase.utils")
local UserMessage = require("senpai.usecase.message.user")
local AssistantMessage = require("senpai.usecase.message.assistant")
local ToolResultMessage = require("senpai.usecase.message.tool_result")

local M = {}
M.__index = M

---send chat to LLM
---@param chat senpai.ChatWindow
function M.execute(chat)
  if chat.is_sending then
    return
  end
  chat.is_sending = true
  local user_input = UserMessage.render_from_request(chat)

  local spinner = Spinner.new(
    "Senpai thinking",
    -- update
    function(message)
      utils.set_winbar(chat.chat_input.winid, message)
    end,
    -- finish
    function(message)
      chat.is_sending = false
      utils.set_winbar(chat.chat_input.winid, message)
      vim.defer_fn(function()
        utils.set_winbar(chat.chat_input.winid, "Ask Senpai")
      end, 2000)
    end
  )
  spinner:start()
  chat.job = RequestHandler.streamRequest({
    method = "post",
    route = "/chat",
    body = {
      thread_id = chat.thread_id,
      provider = chat.provider,
      system_prompt = chat.system_prompt,
      text = user_input,
    },
    stream = function(_, part)
      if not part or not part.type or part.content == "" then
        return
      end
      if part.type == "0" then
        AssistantMessage.render_from_response(chat, part)
      elseif part.type == "a" then
        ToolResultMessage.render_from_response(chat, part)
      end
      utils.scroll_when_invisible(chat)
    end,
    callback = function()
      spinner:stop()
    end,
  })
end

return M
