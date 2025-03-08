local Config = require("senpai.config")

local M = {}

local function wait_async(callback)
  vim.fn["denops#plugin#wait_async"]("senpai", callback)
end

M.hello = function()
  local provider = Config.provider
  local provider_opts = Config.providers["openai"]
  wait_async(function()
    local response = vim.fn["denops#request"]("senpai", "hello", {})
    vim.notify(response)
  end)
end

M.generate_commit_message = function()
  local provider = Config.provider
  local provider_config = Config.providers["openai"]
  wait_async(function()
    local response = vim.fn["denops#request"](
      "senpai",
      "generateCommitMessage",
      { provider, provider_config }
    )
    -- TODO: これを書き込めるようにする
    vim.notify(response)
    return response
  end)
end

return M
