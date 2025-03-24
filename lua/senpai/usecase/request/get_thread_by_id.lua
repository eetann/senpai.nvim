local RequestHandler = require("senpai.usecase.request.request_handler")
local utils = require("senpai.usecase.utils")

local M = {}

---@param thread_id string
---@return senpai.chat.thread
function M.execute(thread_id)
  local response = RequestHandler.request_without_callback({
    method = "get",
    route = "/thread/" .. utils.encode_url(thread_id),
  })
  if response.exit ~= 0 then
    vim.notify(
      "[senpai] failed to get thread `" .. thread_id .. "`",
      vim.log.levels.WARN
    )
    return {}
  end
  local ok, thread = pcall(vim.json.decode, response.body)
  if not ok or type(thread) ~= "table" then
    vim.notify(
      "[senpai] failed to get thread `" .. thread_id .. "`",
      vim.log.levels.WARN
    )
    return {}
  end
  return thread
end

return M
