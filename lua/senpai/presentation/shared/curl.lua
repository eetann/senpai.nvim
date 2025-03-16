local curl = require("plenary.curl")
local Server = require("senpai.presentation.server")

local M = {}

local port = 3000

function M.requestText(route, body)
  Server.start_server()
  local res = curl.post("http://localhost:" .. port .. route, {
    body = vim.fn.json_encode(body),
    headers = {
      content_type = "application/json",
    },
  })
  return res.body
end

return M
