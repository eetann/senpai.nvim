local M = {}

---@doc.type
---@class senpai.Config.agent.auto_accept
---@field replace_in_file? boolean|string[]
---@field execute_command? boolean|string[]
---@field write_to_file? boolean|string[]

---@doc.type
---@class senpai.Config.agent
---@field auto_accept? senpai.Config.agent.auto_accept

---@type senpai.Config.agent
M.default_config = {
  auto_accept = {
    replace_in_file = { "*.md" },
    execute_command = false,
    write_to_file = false,
  },
}

return M
