local curl = require("plenary.curl")
local Server = require("senpai.presentation.server")

local M = {}

local port = 3000

function M.requestText(route, body)
  Server.start_server()
  local res = curl.post("http://localhost:" .. port .. route, {
    -- accept = "text/plain",
    body = vim.fn.json_encode(body),
  })
  return res.body
end

return M
