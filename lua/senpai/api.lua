local ChatBufferManager = require("senpai.presentation.chat_buffer_manager")
local RequestHandler = require("senpai.presentation.shared.request_handler")

local chatBufferManager = ChatBufferManager.new()

local M = {}

function M.hello()
  RequestHandler.request("/hello", nil, function(response)
    if response.exit ~= 0 then
      vim.notify("[senpai] Something is wrong.")
      return
    end
    vim.notify(response.body)
  end)
end

--[=[@doc
  category = "api"
  name = "senpai.toggle_chat()"
  desc = "Toggle chat."
--]=]
function M.toggle_chat()
  chatBufferManager:toggle_current_chat()
end

return setmetatable(M, {
  __index = function(_, k)
    return require("senpai.presentation.commit_message")[k]
      or require("senpai.presentation.summarize")[k]
  end,
})
