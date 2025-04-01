local M = {}

---@class senpai.Config.PromptLauncher.launcher
---@field provider? senpai.Config.provider.name|senpai.Config.provider
---@field system? string|fun():string
---@field user? string|fun():string
---@field priority? number The smaller, the higher the priority.
---@field condition? fun():boolean
---@field thread_id? string

---@alias senpai.Config.prompt_launchers table<string, senpai.Config.PromptLauncher.launcher>

---@class senpai.Config.PromptLauncher.resolved_launcher: senpai.ChatWindowNewArgs
---@field user_prompt? string

return M
