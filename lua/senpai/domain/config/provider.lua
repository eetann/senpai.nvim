local M = {}

---@doc.type
---@alias senpai.Config.provider.name
---| "anthropic"
---| "deepseek"
---| "google"
---| "openai"
---| "openrouter"

---@doc.type
---@class senpai.Config.provider.base
---@field model_id string

---@doc.type
---@class senpai.Config.provider.anthropic: senpai.Config.provider.base
---@field model_id ("claude-3-7-sonnet-20250219"|"claude-3-5-sonnet-20241022"|string)

---@doc.type
---@class senpai.Config.provider.deepseek: senpai.Config.provider.base
---@field model_id ("deepseek-chat"|"deepseek-reasoner"|string)
--- deepseek-reasoner is DeepSeek-R1. Since structured output is not possible,
--- commit message generation cannot be used with deepseek-reasoner.

---@doc.type
---@class senpai.Config.provider.google: senpai.Config.provider.base
---@field model_id ("gemini-2.5-pro-exp-03-25"|"gemini-2.0-flash-001"|string)

---@doc.type
---@class senpai.Config.provider.openai: senpai.Config.provider.base
---@field model_id ("gpt-4.1"|"gpt-4.1-mini"|"gpt-4o"|"gpt-4o-mini"|string)

---@doc.type
---@class senpai.Config.provider.openrouter: senpai.Config.provider.base
---@field model_id ("openai/gpt-4.1"|string)
---   You can get a list of models with the following command.
---   >sh
---   curl https://openrouter.ai/api/v1/models | jq '.data[].id'
---   # check specific model
---   curl https://openrouter.ai/api/v1/models | \
---     jq '.data[] | select(.id == "deepseek/deepseek-r1:free") | .'
--- <

---@class senpai.Config.provider: senpai.Config.provider.base
---@field name senpai.Config.provider.name

---@doc.type
---@class senpai.Config.provider.settings
---@field anthropic? senpai.Config.provider.anthropic
---@field deepseek? senpai.Config.provider.deepseek
---@field google? senpai.Config.provider.google
---@field openai? senpai.Config.provider.openai
---@field openrouter? senpai.Config.provider.openrouter
---@field [string] senpai.Config.provider.base

---@doc.type
---@class senpai.Config.providers: senpai.Config.provider.settings
---@field default senpai.Config.provider.name|string

---@type senpai.Config.providers
M.default_config = {
  default = "openrouter",
  anthropic = { model_id = "claude-3-7-sonnet-20250219" },
  deepseek = { model_id = "deepseek-chat" },
  google = { model_id = "gemini-1.5-pro" },
  openai = { model_id = "gpt-4.1-mini" },
  openrouter = { model_id = "anthropic/claude-3.7-sonnet" },
}

---Validate that the value passed is provider
---@param provider any
function M.validate_provider(provider)
  vim.validate("provider", provider, "table")
  vim.validate("provider.model_id", provider.model_id, "string")
end

---@param option_providers senpai.Config.providers
function M.validate_option_providers(option_providers)
  for key, provider in pairs(option_providers) do
    if key == "default" then
      goto continue
    end
    if not pcall(M.validate_provider, provider) then
      vim.notify(
        "[senpai] please fix `providers." .. key .. "` to the correct structure",
        vim.log.levels.ERROR
      )
    end
    ::continue::
  end

  if
    option_providers.default == "anthropic" and not vim.env.ANTHROPIC_API_KEY
  then
    vim.schedule(function()
      vim.notify("[senpai]: ANTHROPIC_API_KEY is not set", vim.log.levels.WARN)
    end)
  elseif
    option_providers.default == "deepseek" and not vim.env.DEEPSEEK_API_KEY
  then
    vim.schedule(function()
      vim.notify("[senpai]: DEEPSEEK_API_KEY is not set", vim.log.levels.WARN)
    end)
  elseif
    option_providers.default == "google"
    and not vim.env.GOOGLE_GENERATIVE_AI_API_KEY
  then
    vim.schedule(function()
      vim.notify(
        "[senpai]: GOOGLE_GENERATIVE_AI_API_KEY is not set",
        vim.log.levels.WARN
      )
    end)
  elseif
    option_providers.default == "openai" and not vim.env.OPENAI_API_KEY
  then
    vim.schedule(function()
      vim.notify("[senpai]: OPENAI_API_KEY is not set", vim.log.levels.WARN)
    end)
  elseif
    option_providers.default == "openrouter" and not vim.env.OPENROUTER_API_KEY
  then
    vim.schedule(function()
      vim.notify("[senpai]: OPENROUTER_API_KEY is not set", vim.log.levels.WARN)
    end)
  end
end

---@param option_providers senpai.Config.providers
---@param provider? senpai.Config.provider.name|senpai.Config.provider
function M.resove_provider(option_providers, provider)
  if type(provider) == "table" then
    if not pcall(M.validate_provider, provider) then
      return nil
    end
    return provider
  end

  ---@cast provider senpai.Config.provider.name
  local name = provider or option_providers.default
  if name == "" then
    vim.notify(
      "[senpai] please write `providers.default` at config",
      vim.log.levels.ERROR
    )
    return nil
  end

  ---@type senpai.Config.provider
  local option_provider = option_providers[name]
  if not option_provider then
    vim.notify(
      "[senpai] please write `providers.default` at config",
      vim.log.levels.ERROR
    )
    return nil
  end
  option_provider.name = name
  if not pcall(M.validate_provider, option_provider) then
    return nil
  end
  return option_provider
end

return M
