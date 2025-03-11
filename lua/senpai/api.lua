local Config = require("senpai.config")
local WithDenops = require("senpai.presentation.shared.with_denops")
local Chat = require("senpai.presentation.chat")

local M = {}

function M.hello()
  local provider = Config.provider
  local provider_opts = Config.providers[provider]
  WithDenops.wait_for_setup()
  local response = vim.fn["denops#request"]("senpai", "hello", {})
  vim.notify(response)
end

function M.open_chat()
  local chat = Chat.new()
  chat:show()
end

return setmetatable(M, {
  __index = function(_, k)
    return require("senpai.presentation.commit_message")[k]
      or require("senpai.presentation.summarize")[k]
  end,
})
