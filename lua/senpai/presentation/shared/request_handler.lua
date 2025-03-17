local async = require("plenary.async")
local curl = require("plenary.curl")
local Server = require("senpai.presentation.server")

local M = {}

local port = 3000

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

---@alias senpai.RequestHandler.callback fun(response: senpai.RequestHandler.return): nil

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

---@param route string
---@param body table|nil
---@param callback senpai.RequestHandler.callback
---@return nil
function M.request(route, body, callback)
  Server.start_server()
  async.void(function()
    local response = M.post({
      url = "http://localhost:" .. port .. route,
      body = body and vim.fn.json_encode(body) or nil,
      headers = {
        content_type = "application/json",
      },
    })
    vim.schedule(function()
      callback(response)
    end)
  end)()
end

return M
