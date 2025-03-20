local RequestHandler = require("senpai.presentation.shared.request_handler")

local M = {}

---@param callback fun(threads: senpai.chat.thread[]): nil
---@return nil
function M.execute(callback)
  RequestHandler.request({
    method = "get",
    route = "/thread",
    callback = function(response)
      if response.exit ~= 0 then
        vim.notify("[senpai] failed to get threads", vim.log.levels.WARN)
        return
      end
      local ok, threads = pcall(vim.json.decode, response.body)
      if not ok or type(threads) ~= "table" then
        vim.notify("[senpai] failed to get threads", vim.log.levels.WARN)
        return
      end
      callback(threads)
    end,
  })
end

return M
