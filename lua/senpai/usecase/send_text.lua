local Spinner = require("senpai.presentation.shared.spinner")
local RequestHandler = require("senpai.usecase.request.request_handler")
local utils = require("senpai.usecase.utils")
local UserMessage = require("senpai.usecase.message.user")
local AssistantMessage = require("senpai.usecase.message.assistant")
local ToolResultMessage = require("senpai.usecase.message.tool_result")

local M = {}
M.__index = M

---send chat to LLM
---@param chat senpai.IChatWindow
function M.execute(chat)
  if chat.is_sending then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(chat.input_area.bufnr, 0, -1, false)
  local user_input = table.concat(lines, "\n")
  if user_input == "" then
    return
  end

  chat.is_sending = true
  UserMessage.render_from_request(chat, lines)
  local assistant = AssistantMessage.new(chat)

  local spinner = Spinner.new(
    "Senpai thinking",
    -- update
    function(message)
      utils.set_winbar(chat.input_area.winid, message)
    end,
    -- finish
    function(message)
      chat.is_sending = false
      utils.set_winbar(chat.input_area.winid, message)
      vim.defer_fn(function()
        utils.set_winbar(chat.input_area.winid, "Ask Senpai")
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
        assistant:render_from_response(part)
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
