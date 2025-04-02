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

---@param target any
function M.validate(target)
  vim.validate("servers", target.servers, function(servers)
    if type(servers) ~= "table" then
      return false, "mcp.servers should be a `table|nil`"
    end
    for name, server in pairs(servers) do
      if name:match("[^0-9a-zA-Z%-_]") then
        return false,
          "The string that can be used for the name MCP server is as follows: `[0-9a-zA-Z-_]`"
      end
    end
    return true
  end)
end

return M
