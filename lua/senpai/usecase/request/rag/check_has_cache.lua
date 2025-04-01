local RequestHandler = require("senpai.usecase.request.request_handler")

local M = {}

---@param source string
---@return boolean # check if source has cache
function M.execute(source)
  local response = RequestHandler.request_without_callback({
    method = "post",
    route = "/rag/check-cache",
    body = { source = source },
  })
  if response.exit ~= 0 or response.status ~= 200 then
    return false
  end
  local ok, body = pcall(vim.json.decode, response.body)
  if not ok or type(body) ~= "table" then
    return false
  end
  return body.hasCache or false
end

return M
