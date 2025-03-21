local RequestHandler = require("senpai.presentation.shared.request_handler")

local M = {}

---@return senpai.chat.thread[]
function M.execute()
  local response = RequestHandler.request_without_callback({
    method = "get",
    route = "/thread",
  })
  if response.exit ~= 0 then
    vim.notify("[senpai] failed to get threads", vim.log.levels.WARN)
    return {}
  end
  local ok, threads = pcall(vim.json.decode, response.body)
  if not ok or type(threads) ~= "table" then
    vim.notify("[senpai] failed to get threads", vim.log.levels.WARN)
    return {}
  end
  return threads
end

return M
