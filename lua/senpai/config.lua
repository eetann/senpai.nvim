---@alias provider "openai"

---@tag senpai-config
---@toc_entry Config
---@class senpai.Config
---@field provider? provider
---@field providers? senpai.Config.providers see |senpai-config-providers|
---
---@eval return require("senpai.config")._format_default()

---@tag senpai-config-providers
---@class senpai.Config.providers
---@field openai senpai.Config.providers.OpenAIProvider
---   see |senpai-config-providers-openaiprovider|
---
---@field anthropic senpai.Config.providers.AnthropicProvider
---   see |senpai-config-providers-anthropicprovider|

---@tag senpai-config-providers-openaiprovider
---@class senpai.Config.providers.OpenAIProvider
---@field model ("gpt-4o" | "gpt-4o-mini")

---@tag senpai-config-providers-anthropicprovider
---@class senpai.Config.providers.AnthropicProvider
---@field model ("claude-3-7-sonnet-20250219" | "claude-3-5-sonnet-20241022")

---@private
---@type senpai.Config
local default_config = {
  provider = "openai",
  providers = {
    openai = { model = "gpt-4o" },
    anthropic = { model = "claude-3-7-sonnet-20250219" },
  },
}

---@type senpai.Config
---@private
local options

---@nodoc
---@class senpai.Config.mod: senpai.Config
local M = {}

---@nodoc
---@param opts? senpai.Config
function M.setup(opts)
  opts = opts or {}
  options = vim.tbl_deep_extend("force", default_config, opts)
  if options.provider == "openai" and not vim.env.OPENAI_API_KEY then
    vim.notify("[senpai]: OPENAI_API_KEY is not set", vim.log.levels.WARN)
  end
end

-- use in doc
function M._format_default()
  local lines = { "Default values:", ">lua" }
  for line in vim.gsplit(vim.inspect(default_config), "\n") do
    table.insert(lines, "  " .. line)
  end
  table.insert(lines, "<")
  return lines
end

return setmetatable(M, {
  __index = function(_, k)
    return options[k]
  end,
})
