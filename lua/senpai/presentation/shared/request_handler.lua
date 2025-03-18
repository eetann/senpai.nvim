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

---@class senpai.data_stream_protocol
---@field type string|nil
---@field content string|table

---parse "Data Stream Protocol by AI SDK"
-- https://sdk.vercel.ai/docs/ai-sdk-ui/stream-protocol#data-stream-protocol
---@param stream_part string|nil
---@return senpai.data_stream_protocol
function M.parse_stream_part(stream_part)
  if not stream_part or stream_part == "" then
    return { type = nil, content = "" }
  end
  -- TYPE_ID:CONTENT_JSON
  local type_id, content_json = stream_part:match("^([^:]+):(.+)$")
  if not type_id or not content_json then
    return { type = nil, content = "" }
  end

  local success, content = pcall(vim.json.decode, content_json)
  if not success then
    return { type = nil, content = tostring(content) }
  end

  return {
    type = type_id,
    content = content,
  }
end

---@alias senpai.RequestHandler.stream_fun fun(error: string, data: senpai.data_stream_protocol?): nil

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
      stream = function(error, data)
        vim.schedule(function()
          if error then
            vim.notify(
              "[senpai] stream failed: " .. error,
              vim.log.levels.ERROR
            )
          end
          local part = M.parse_stream_part(data)
          args.stream(error, part)
        end)
      end,
    })
    vim.schedule(function()
      args.callback(response)
    end)
  end)()
end

return M
