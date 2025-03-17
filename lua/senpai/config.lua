---@alias provider "openai" | "openrouter"

---@doc.type
---@class senpai.Config.providers.Provider
---@field model string

---@doc.type
---@class senpai.Config.providers.OpenAIProvider
---@field model ("gpt-4o" | "gpt-4o-mini")

---@doc.type
---@class senpai.Config.providers.AnthropicProvider
---@field model ("claude-3-7-sonnet-20250219" | "claude-3-5-sonnet-20241022")

---@doc.type
---@class senpai.Config.providers.OpenRouterProvider
---@field model string
---   You can get a list of models with the following command.
---   >sh
---   curl https://openrouter.ai/api/v1/models | jq '.data[].id'
---   # check specific model
---   curl https://openrouter.ai/api/v1/models | \
---     jq '.data[] | select(.id == "deepseek/deepseek-r1:free") | .'
--- <

local providers = {
  ---@type senpai.Config.providers.OpenAIProvider
  openai = { model = "gpt-4o" },
  ---@type senpai.Config.providers.AnthropicProvider
  anthropic = { model = "claude-3-7-sonnet-20250219" },
  ---@type senpai.Config.providers.OpenRouterProvider
  openrouter = { model = "anthropic/claude-3.7-sonnet" },
}

---@doc.type
---@class senpai.Config
---@field provider? provider
---@field providers? table<string, senpai.Config.providers.Provider>
---@field commit_message? senpai.Config.commit_message
---@field port? number Internal local host port number

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
  provider = "openai",
  providers = providers,
  commit_message = {
    language = "English",
  },
  port = 9942,
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
    vim.schedule(function()
      vim.notify("[senpai]: OPENAI_API_KEY is not set", vim.log.levels.WARN)
    end)
  end
  if options.provider == "openrouter" and not vim.env.OPENROUTER_API_KEY then
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

---@return provider
---@return senpai.Config.providers.Provider
function M.get_provider()
  return options.provider, options.providers[options.provider]
end

return setmetatable(M, {
  __index = function(_, k)
    return options[k]
  end,
})
