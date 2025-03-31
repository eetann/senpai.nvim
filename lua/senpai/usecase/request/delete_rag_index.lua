local RequestHandler = require("senpai.usecase.request.request_handler")
local utils = require("senpai.usecase.utils")

local M = {}

---@param index_name string
---@param callback fun(index_name:string, response: senpai.RequestHandler.return): nil
---@return nil
function M.execute(index_name, callback)
  RequestHandler.request({
    method = "delete",
    route = "/rag/" .. utils.encode_url(index_name),
    callback = function(response)
      if response.exit ~= 0 then
        vim.notify(
          "[senpai] failed to delete index from RAG: " .. index_name,
          vim.log.levels.WARN
        )
        return
      end
      callback(index_name, response)
    end,
  })
end

return M
