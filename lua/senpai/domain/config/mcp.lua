local M = {}

---@class senpai.Config.mcp.server.stdio
---@field command string
---@field args? string[]
---@field env? table<string, string>
---@field cwd? string

---@class senpai.Config.mcp.server.sse
---@field url string

---@alias senpai.Config.mcp.server
---| senpai.Config.mcp.server.stdio
---| senpai.Config.mcp.server.sse

---@class senpai.Config.mcp
---@field servers? table<string, senpai.Config.mcp.server>

---@type senpai.Config.mcp
M.default_config = {
  servers = {},
}

-- ---@param target any
-- ---@return senpai.Config.mcp
-- function M.validate(target)
--   return
-- end

return M
