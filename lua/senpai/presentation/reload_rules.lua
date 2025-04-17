local RequestHandler = require("senpai.usecase.request.request_handler")

local M = {}

--[=[@doc
  category = "api"
  name = "reload_rules"
  desc = """
```lua
senpai.reload_rules()
```
Reload Project rules and MCP settings
"""
--]=]
function M.reload_rules()
  return RequestHandler.request({
    method = "get",
    route = "/rule",
    callback = function(response)
      if response.exit ~= 0 or response.status ~= 200 then
        vim.notify("[senpai] Failed to reload project rules.")
        return
      end
      vim.notify("[senpai] Reloaded project rules.")
    end,
  })
end

return M
