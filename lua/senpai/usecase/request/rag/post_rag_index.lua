local RequestHandler = require("senpai.usecase.request.request_handler")

local M = {}

---@class senpai.RAG.type.url
---@field type "url"
---@field url string

---@alias senpai.RAG.body senpai.RAG.type.url

---@param body senpai.RAG.body
---@param callback senpai.RequestHandler.callback_fun
---@param finish_callback fun():nil For example, stopping a spinner.
function M.execute(body, callback, finish_callback)
  RequestHandler.request({
    method = "post",
    route = "/rag",
    body = body,
    callback = callback,
  }, finish_callback)
end

return M
