---@alias provider "openai"

---@tag senpai-config
---@toc_entry Config
---@class senpai.Config
---@field provider? provider
---@field providers? senpai.Config.providers see |senpai-config-providers|
---@field commit_message? senpai.Config.commit_message
---   see |senpai-config-commit-message|
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

---@tag senpai-config-commit-message
---@class senpai.Config.commit_message
---@field language string|(fun(): string) Supports languages that AI knows
---   It doesn't have to be strictly natural language,
---   since the prompt is as follows
---   >typescript
---    `subject and body should be written in ${language}.`
--- <
---   That means the AI can write it in a tsundere style as well.
---   Like this.
---     `:Senpai commitMessage English(Tsundere)`

---@private
---@type senpai.Config
local default_config = {
  provider = "openai",
  providers = {
    openai = { model = "gpt-4o" },
    anthropic = { model = "claude-3-7-sonnet-20250219" },
  },
  commit_message = {
    language = "English",
  },
}

---@private
---@type senpai.Config
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
    vim.schedule(function()
      vim.notify("[senpai]: OPENAI_API_KEY is not set", vim.log.levels.WARN)
    end)
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

---@return string
function M.get_commit_message_language()
  local language = options.commit_message.language
  if type(language) == "function" then
    return language()
  end
  return language
end

return setmetatable(M, {
  __index = function(_, k)
    return options[k]
  end,
})
