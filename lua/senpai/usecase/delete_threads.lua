local RequestHandler = require("senpai.presentation.shared.request_handler")
local utils = require("senpai.usecase.utils")

local M = {}

---@param thread_id string
---@param callback fun(): nil
---@return nil
function M.execute(thread_id, callback)
  RequestHandler.request({
    method = "delete",
    route = "/thread/" .. utils.encode_url(thread_id),
    callback = function(response)
      if response.exit ~= 0 then
        vim.notify("[senpai] failed to delete threads", vim.log.levels.WARN)
        return
      end
      callback()
    end,
  })
end

return M
