local Config = require("senpai.config")
local WithDenops = require("senpai.presentation.shared.with_denops")
local Chat = require("senpai.presentation.chat_buffer")

local M = {}

---@tag senpai-summarize
---@text
--- Use AI to summarize input text
---@param text string
function M.summarize(text)
  local chat = Chat:new()
  chat:show()

  local provider, provider_config = Config.get_provider()
  if not provider_config then
    vim.notify("[senpai] provider not found", vim.log.levels.WARN)
    return ""
  end
  WithDenops.wait_async_for_setup(function()
    vim.fn["denops#notify"]("senpai", "summarize", {
      {
        provider = provider,
        provider_config = provider_config,
        bufnr = chat:get_log_buf(),
        text = text,
      },
    })
  end)
end

return M
