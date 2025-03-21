local Provider = require("senpai.domain.config.provider")
local ChatConfig = require("senpai.domain.config.chat")

---@doc.type
---@class senpai.Config
---@field providers? senpai.Config.providers
---@field commit_message? senpai.Config.commit_message
---@field chat? senpai.Config.chat

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
  providers = {
    default = "openrouter",
    openai = { model_id = "gpt-4o" },
    anthropic = { model_id = "claude-3-7-sonnet-20250219" },
    openrouter = { model_id = "anthropic/claude-3.7-sonnet" },
  },
  commit_message = {
    language = "English",
  },
  chat = ChatConfig.default_config,
}

---@type senpai.Config
local options

---@class senpai.Config.mod: senpai.Config
local M = {}

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

---@param provider? senpai.Config.provider.name|senpai.Config.provider
---@return senpai.Config.provider?
function M.get_provider(provider)
  local error = Provider.validate_provider(provider)
  if error == "" then
    return provider --[[@as senpai.Config.provider]]
  elseif type(provider) == "table" then
    vim.notify(
      "[senpai] " .. error .. vim.inspect(provider),
      vim.log.levels.ERROR
    )
    return nil
  end

  local name = provider --[[@as senpai.Config.provider.name]]
    or options.providers.default
  if name == "" then
    vim.notify("[senpai] please write `providers.default", vim.log.levels.ERROR)
    return nil
  end

  ---@class senpai.Config.provider
  local option_provider = options.providers[name]
  if not option_provider then
    vim.notify(
      "[senpai] please write `providers." .. name .. "`",
      vim.log.levels.ERROR
    )
    return nil
  end
  option_provider.name = name
  if not Provider.validate_provider(option_provider) then
    vim.notify(
      "[senpai] please fix `providers." .. name .. "` to the correct structure",
      vim.log.levels.ERROR
    )
    return nil
  end
  return option_provider
end

function M.validate_option_providers(option_providers)
  for key, provider in pairs(option_providers) do
    if key == "default" then
      goto continue
    end
    if not Provider.validate_provider(provider) then
      vim.notify(
        "[senpai] please fix `providers." .. key .. "` to the correct structure",
        vim.log.levels.ERROR
      )
    end
    ::continue::
  end
end

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
  vim.schedule(function()
    M.validate_option_providers(options.providers)
  end)
end

return setmetatable(M, {
  __index = function(_, k)
    return options[k]
  end,
})
