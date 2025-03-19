---@alias senpai.Config.provider.name
---| "openai"
---| "openrouter"

---@doc.type
---@class senpai.Config.provider.base
---@field model string

---@doc.type
---@class senpai.Config.provider.openai: senpai.Config.provider.base
---@field model ("gpt-4o" | "gpt-4o-mini"|string)

---@doc.type
---@class senpai.Config.provider.anthropic: senpai.Config.provider.base
---@field model ("claude-3-7-sonnet-20250219" | "claude-3-5-sonnet-20241022"|string)

---@doc.type
---@class senpai.Config.provider.openrouter: senpai.Config.provider.base
---@field model string
---   You can get a list of models with the following command.
---   >sh
---   curl https://openrouter.ai/api/v1/models | jq '.data[].id'
---   # check specific model
---   curl https://openrouter.ai/api/v1/models | \
---     jq '.data[] | select(.id == "deepseek/deepseek-r1:free") | .'
--- <

---@class senpai.Config.provider: senpai.Config.provider.base
---@field name senpai.Config.provider.name

---@class senpai.Config.provider.settings
---@field openai? senpai.Config.provider.openai
---@field anthropic? senpai.Config.provider.anthropic
---@field openrouter? senpai.Config.provider.openrouter
---@field [string] senpai.Config.provider.base

---@class senpai.Config.providers: senpai.Config.provider.settings
---@field default senpai.Config.provider.name|string

---@type senpai.Config.providers
local providers = {
  default = "openrouter",
  openai = { model = "gpt-4o" },
  anthropic = { model = "claude-3-7-sonnet-20250219" },
  openrouter = { model = "anthropic/claude-3.7-sonnet" },
}

---@doc.type
---@class senpai.Config
---@field providers? senpai.Config.providers
---@field commit_message? senpai.Config.commit_message

---@doc.type
---@class senpai.Config.commit_message
---@field language string|(fun(): string) Supports languages that AI knows
---   It doesn't have to be strictly natural language,
---   since the prompt is as follows
---    `subject and body should be written in ${language}.`
---   That means the AI can write it in a tsundere style as well.
---   Like this.
---     `:Senpai commitMessage English(Tsundere)`

---@type senpai.Config
local default_config = {
  providers = providers,
  commit_message = {
    language = "English",
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
  if options.providers.default == "openai" and not vim.env.OPENAI_API_KEY then
    vim.schedule(function()
      vim.notify("[senpai]: OPENAI_API_KEY is not set", vim.log.levels.WARN)
    end)
  end
  if
    options.providers.default == "openrouter" and not vim.env.OPENROUTER_API_KEY
  then
    vim.schedule(function()
      vim.notify("[senpai]: OPENROUTER_API_KEY is not set", vim.log.levels.WARN)
    end)
  end
end

-- use in doc
function M._format_default()
  local lines = { "```lua" }
  for line in vim.gsplit(vim.inspect(default_config), "\n") do
    table.insert(lines, line)
  end
  table.insert(lines, "```")
  return table.concat(lines, "\n")
end

---@return string
function M.get_commit_message_language()
  local language = options.commit_message.language
  if type(language) == "function" then
    return language()
  end
  return language
end

---@return senpai.Config.provider?
function M.get_provider()
  local default_provider = options.providers.default
  if not default_provider then
    vim.notify("[senpai] please write `providers.default", vim.log.levels.ERROR)
    return nil
  end
  local provider = options.providers[default_provider]
  if not provider then
    vim.notify(
      "[senpai] please write `providers." .. default_provider .. "`",
      vim.log.levels.ERROR
    )
    return nil
  end
  return provider
end

return setmetatable(M, {
  __index = function(_, k)
    return options[k]
  end,
})
