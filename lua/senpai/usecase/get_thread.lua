local RequestHandler = require("senpai.presentation.shared.request_handler")

local M = {}

---@param thread_id string
---@param callback senpai.RequestHandler.callback_fun
---@return nil
function M.get_thread(thread_id, callback)
  RequestHandler.request({
    method = "post",
    route = "/thread/messages",
    body = {
      thread_id = thread_id,
    },
    callback = function(response)
      if response.exit ~= 0 then
        vim.notify(
          "[senpai] failed to get thread " .. thread_id,
          vim.log.levels.WARN
        )
      end
      -- TODO: ここから
      callback(vim.json.decocde(response.body))
    end,
  })
end

return M
