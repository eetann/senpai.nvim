local ChatBufferManager = require("senpai.presentation.chat_buffer_manager")
local Curl = require("senpai.presentation.shared.curl")

local chatBufferManager = ChatBufferManager.new()

local M = {}

function M.hello()
  local response = Curl.requestText("/hello")
  vim.notify(response)
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
