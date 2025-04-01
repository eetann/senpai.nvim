local RequestHandler = require("senpai.usecase.request.request_handler")

local M = {}

---@param source string
---@return nil
function M.execute(source)
  RequestHandler.request({
    method = "delete",
    route = "/rag",
    body = {
      source = source,
    },
    callback = function(response)
      if response.exit ~= 0 then
        vim.notify(
          "[senpai] failed to delete index from RAG: " .. source,
          vim.log.levels.WARN
        )
        return
      end
      if response.status == 204 then
        vim.notify("[senpai] Deleted from RAG: " .. source, vim.log.levels.INFO)
        return
      end
      vim.notify(
        "[senpai] Deletion from RAG failed: " .. source,
        vim.log.levels.WARN
      )
    end,
  })
end

return M
