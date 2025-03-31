local RequestHandler = require("senpai.usecase.request.request_handler")

local M = {}

---@return string[] # indexName list
function M.execute()
  local response = RequestHandler.request_without_callback({
    method = "get",
    route = "/rag",
  })
  if response.exit ~= 0 then
    vim.notify("[senpai] failed to get RAG list", vim.log.levels.WARN)
    return {}
  end
  local ok, indexes = pcall(vim.json.decode, response.body)
  if not ok or type(indexes) ~= "table" then
    vim.notify("[senpai] failed to get RAG list", vim.log.levels.WARN)
    return {}
  end
  return indexes
end

return M
