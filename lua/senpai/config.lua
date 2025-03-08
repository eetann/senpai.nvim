---@alias provider "openai"

---@class OpenAIProvider
---@field model "gpt-4o" | "gpt-4o-mini"

---@class AnthropicProvider
---@field model "claude-3-7-sonnet-20250219" | "claude-3-5-sonnet-20241022"

---@class senpai.Provider
---@field model string

---@class senpai.Providers
---@field openai OpenAIProvider
---@field anthropic AnthropicProvider

---@tag senpai-config
---@text
---
---@class senpai.Config
---@field provider? provider
---@field providers? senpai.Providers
local default_config = {
  provider = "openai",
  providers = {
    openai = { model = "gpt-4o" },
    anthropic = { model = "claude-3-7-sonnet-20250219" },
  },
}

---@type senpai.Config
local options

---@class senpai.Config.mod: senpai.Config
local M = {}

---@param opts? senpai.Config
function M.setup(opts)
  opts = opts or {}
  options = vim.tbl_deep_extend("force", default_config, opts)
  if options.provider == "openai" and not vim.env.OPENAI_API_KEY then
    vim.notify("[senpai]: OPENAI_API_KEY is not set", vim.log.levels.WARN)
  end
end

return setmetatable(M, {
  __index = function(_, k)
    return options[k]
  end,
})
