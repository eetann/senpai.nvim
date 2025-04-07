local RequestHandler = require("senpai.usecase.request.request_handler")
local content_popup = require("senpai.usecase.popup.content_popup")
local M = {}

function M.execute()
  local response = RequestHandler.request_without_callback({
    method = "get",
    route = "/mcp",
  })
  if response.exit ~= 0 then
    vim.notify("[senpai] failed to get MCP Tools ", vim.log.levels.WARN)
    return {}
  end
  local ok, tools = pcall(vim.json.decode, response.body)
  if not ok or type(tools) ~= "table" then
    vim.notify("[senpai] failed to get MCP Tools ", vim.log.levels.WARN)
    return {}
  end
  local content = ""
  if
    (type(tools) == "table" and next(tools) == nil)
    or not tools
    or tools == ""
  then
    content = "*No MCP Tools*"
  else
    content = vim.inspect(tools)
  end

  content_popup.execute("MCP Tools", content)
end

return M
