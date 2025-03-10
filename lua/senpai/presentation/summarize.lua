local Config = require("senpai.config")
local WithDenops = require("senpai.presentation.shared.with_denops")

local M = {}

---@tag senpai-summarize
---@text
--- Use AI to summarize input text
---@param text string
---@return string
function M.summarize(text)
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
        text = text,
      },
    })
  end)
end

return M
