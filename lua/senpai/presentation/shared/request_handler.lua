local async = require("plenary.async")
local curl = require("plenary.curl")
local Server = require("senpai.presentation.server")

local M = {}

---@class senpai.RequestHandler.opts
---@field url string The url to make the request to.
---@field query? table url query, append after the url
---@field body? string|table The request body
---@field auth? string|string[] Basic request auth, 'user:pass', or {"user", "pass"}
---@field form? table request form
---@field raw? table any additonal curl args, it must be an array/list
---@field dry_run? boolean whether to return the args to be ran through curl
---@field output? string where to download something
---@field timeout? number request timeout in mseconds
---@field http_version? 'HTTP/0.9'|'HTTP/1.0'|'HTTP/1.1'|'HTTP/2'|'HTTP/3'
---@field proxy? string [protocol://]host[:port] Use this proxy
---@field insecure? boolean Allow insecure server connections

---@class senpai.RequestHandler.return
---@field exit number The shell process exit code
---@field status number The https response status
---@field headers table The https response headers
---@field body string The http response body

---@alias senpai.RequestHandler.callback_fun fun(response: senpai.RequestHandler.return): nil

---@type fun(opts: senpai.RequestHandler.opts): senpai.RequestHandler.return
M.get = async.wrap(function(opts, callback)
  opts.callback = callback
  curl.get(opts)
end, 2)

---@type fun(opts: senpai.RequestHandler.opts): senpai.RequestHandler.return
M.post = async.wrap(function(opts, callback)
  opts.callback = callback
  curl.post(opts)
end, 2)

---@class senapi.RequestHandler.callback_args
---@field route string
---@field body table|nil
---@field callback senpai.RequestHandler.callback_fun

---@param args senapi.RequestHandler.callback_args
---@return nil
function M.request(args)
  Server.start_server()
  if not Server.port then
    vim.notify(
      "[senpai] Server startup failed. Please try again.",
      vim.log.levels.ERROR
    )
    return
  end
  async.void(function()
    local response = M.post({
      url = "http://localhost:" .. Server.port .. args.route,
      body = args.body and vim.fn.json_encode(args.body) or nil,
      headers = {
        content_type = "application/json",
      },
    })
    vim.schedule(function()
      args.callback(response)
    end)
  end)()
end

---@alias senpai.RequestHandler.stream_fun fun(error: string, data: string): nil

---@class senapi.RequestHandler.stream_args
---@field route string
---@field body table|nil
---@field stream senpai.RequestHandler.stream_fun
---@field callback senpai.RequestHandler.callback_fun

---@param args senapi.RequestHandler.stream_args
---@return nil
function M.streamRequest(args)
  Server.start_server()
  if not Server.port then
    vim.notify(
      "[senpai] Server startup failed. Please try again.",
      vim.log.levels.ERROR
    )
    return
  end
  async.void(function()
    local response = M.post({
      url = "http://localhost:" .. Server.port .. args.route,
      body = args.body and vim.fn.json_encode(args.body) or nil,
      headers = {
        content_type = "application/json",
      },
      raw = { "--no-buffer" }, -- NOTE: IMPORTANT!
      stream = args.stream,
    })
    vim.schedule(function()
      args.callback(response)
    end)
  end)()
end

return M
