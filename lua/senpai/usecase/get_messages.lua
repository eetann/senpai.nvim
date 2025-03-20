local RequestHandler = require("senpai.presentation.shared.request_handler")

local M = {}

---@param thread_id string
---@param callback fun(messages: senpai.chat.message?): nil
---@return nil
function M.execute(thread_id, callback)
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
      local ok, messages = pcall(vim.json.decode, response.body)
      if not ok or type(messages) ~= "table" then
        messages = {}
      end
      callback(messages)
    end,
  })
end

return M
