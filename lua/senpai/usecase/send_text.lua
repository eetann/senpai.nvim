local Spinner = require("senpai.presentation.shared.spinner")
local RequestHandler = require("senpai.presentation.shared.request_handler")
local utils = require("senpai.usecase.utils")

local M = {}
M.__index = M

---send chat to LLM
---@param chat senpai.ChatWindow
function M:execute(chat)
  local lines = vim.api.nvim_buf_get_lines(chat.chat_input.bufnr, 0, -1, false)
  vim.api.nvim_buf_set_lines(chat.chat_input.bufnr, 0, -1, false, {})
  local user_input = utils.process_user_input(chat, lines)

  local spinner = Spinner.new(
    "Senpai thinking",
    -- update
    function(message)
      utils.set_winbar(chat.chat_input.winid, message)
    end,
    -- finish
    function(message)
      utils.set_winbar(chat.chat_input.winid, message)
      vim.defer_fn(function()
        utils.set_winbar(chat.chat_input.winid, "Ask Senpai")
      end, 2000)
    end
  )
  spinner:start()
  RequestHandler.streamRequest({
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
        utils.set_text_at_last(
          chat.chat_log.bufnr,
          part.content --[[@as string]]
        )
        utils.scroll_when_invisible(chat)
      end
    end,
    callback = function()
      spinner:stop()
    end,
  })
end

return M
