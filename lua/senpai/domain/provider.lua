local M = {}

---@alias senpai.Config.provider.name
---| "openai"
---| "openrouter"

---@doc.type
---@class senpai.Config.provider.base
---@field model_id string

---@doc.type
---@class senpai.Config.provider.openai: senpai.Config.provider.base
---@field model_id ("gpt-4o" | "gpt-4o-mini"|string)

---@doc.type
---@class senpai.Config.provider.anthropic: senpai.Config.provider.base
---@field model_id ("claude-3-7-sonnet-20250219" | "claude-3-5-sonnet-20241022"|string)

---@doc.type
---@class senpai.Config.provider.openrouter: senpai.Config.provider.base
---@field model_id string
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

---Validate that the value passed is provider
---@param target any
---@return string
function M.validate_provider(target)
  if type(target) ~= "table" then
    return "It is not table"
  end
  if type(target.name) ~= "string" then
    return "correct name"
  end
  if type(target.model_id) ~= "string" then
    return "correct model_id"
  end
  return ""
end

return M
