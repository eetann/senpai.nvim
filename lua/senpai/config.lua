local ProviderConfig = require("senpai.domain.config.provider")
local ChatConfig = require("senpai.domain.config.chat")
local CommandConfig = require("senpai.domain.config.command")
local RagConfig = require("senpai.domain.config.rag")
local McpConfig = require("senpai.domain.config.mcp")
local InternalLog = require("senpai.presentation.internal_log")

---@doc.type
---@class senpai.Config
---@field providers? senpai.Config.providers
---@field commit_message? senpai.Config.commit_message
---@field chat? senpai.Config.chat
---@field command? senpai.Config.command
---@field rag? senpai.Config.rag
---@field prompt_launchers? senpai.Config.prompt_launchers
---@field mcp? senpai.Config.mcp
---@field debug? boolean

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
  providers = ProviderConfig.default_config,
  commit_message = {
    language = "English",
  },
  chat = ChatConfig.default_config,
  command = CommandConfig.default_config,
  rag = RagConfig.default_config,
  prompt_launchers = {
    ["Tsundere"] = {
      system = "Answers should be tsundere style.",
      priority = 100,
    },
    ["Senpai"] = {
      system = "Answer as a senpai with a crazy casual tone.",
      priority = 99,
    },
  },
  mcp = McpConfig.default_config,
  debug = false,
}

---@type senpai.Config
local options

---@class senpai.Config.mod: senpai.Config
local M = {}

---@type senpai.InternalLog?
M.internal_log = nil

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
  return ProviderConfig.resove_provider(options.providers, provider)
end

---@param opts? senpai.Config
function M.setup(opts)
  opts = opts or {}
  options = vim.tbl_deep_extend("force", default_config, opts)
  ProviderConfig.validate_option_providers(options.providers)
  McpConfig.validate(options.mcp)
  if opts.debug then
    M.internal_log = InternalLog.new()
  end
end

return setmetatable(M, {
  __index = function(_, k)
    return options[k]
  end,
})
