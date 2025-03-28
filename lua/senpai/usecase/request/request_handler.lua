local curl = require("plenary.curl")
local Client = require("senpai.presentation.client")

local M = {}

---@class senpai.RequestHandler.return
---@field exit number The shell process exit code
---@field status number The https response status
---@field headers table The https response headers
---@field body string The http response body

---@class senpai.data_stream_protocol
---@field type string|nil
---@field content string|table

---@alias senpai.RequestHandler.callback_fun fun(response: senpai.RequestHandler.return): nil
---@alias senpai.RequestHandler.stream_fun fun(error: string, data: senpai.data_stream_protocol?): nil

---@class senpai.RequestHandler.opts
---@field method "get"|"post"|"put"|"head"|"patch"|"delete"
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
---@field callback? senpai.RequestHandler.callback_fun
---@field stream? fun(error: string, data: string|nil): nil

---@class senapi.RequestHandler.base_args
---@field method "get"|"post"|"put"|"head"|"patch"|"delete"
---@field route string
---@field body table|nil

---@class senapi.RequestHandler.callback_args : senapi.RequestHandler.base_args
---@field callback senpai.RequestHandler.callback_fun

---@class senapi.RequestHandler.stream_args : senapi.RequestHandler.base_args
---@field stream senpai.RequestHandler.stream_fun

---@param args senapi.RequestHandler.base_args
---@return senpai.RequestHandler.opts?
local function create_opts(args)
  Client.start_server()
  if not Client.port then
    vim.notify(
      "[senpai] Server startup failed. Please try again.",
      vim.log.levels.ERROR
    )
    return nil
  end
  return {
    method = args.method,
    url = "http://localhost:" .. Client.port .. args.route,
    body = args.body and vim.fn.json_encode(args.body) or nil,
    headers = {
      content_type = "application/json",
    },
  }
end

---@param args senapi.RequestHandler.callback_args|senapi.RequestHandler.stream_args
---@param finish_callback fun():nil For example, stopping a spinner.
---@param use_stream boolean
---@return Job?
function M._request_base(args, finish_callback, use_stream)
  local opts = create_opts(args)
  if use_stream then
    opts.raw = { "--no-buffer" }
    opts.stream = function(error, data)
      vim.schedule(function()
        if error then
          vim.notify("[senpai] stream failed: " .. error, vim.log.levels.ERROR)
        end
        local part = M.parse_stream_part(data)
        args.stream(error, part)
      end)
    end
  end

  opts.callback = vim.schedule_wrap(function(response)
    finish_callback()
    args.callback(response)
  end)
  return curl.request(opts)
end

---@param args senapi.RequestHandler.callback_args
---@param finish_callback? fun():nil For example, stopping a spinner.
---@return Job?
function M.request(args, finish_callback)
  return M._request_base(args, finish_callback or function() end, false)
end

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

---@param args senapi.RequestHandler.stream_args
---@param finish_callback? fun():nil For example, stopping a spinner.
---@return Job?
function M.streamRequest(args, finish_callback)
  return M._request_base(args, finish_callback or function() end, true)
end

---@param args senapi.RequestHandler.base_args
---@return senpai.RequestHandler.return
function M.request_without_callback(args)
  local opts = create_opts(args)
  return curl.request(opts) --[[@as senpai.RequestHandler.return]]
end

return M
