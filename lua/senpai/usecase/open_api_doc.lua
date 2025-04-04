local Client = require("senpai.presentation.client")

local M = {}

function M.execute()
  local url = M.get_server_url()
  if url == "" then
    vim.notify("[senpai] Internal server is not up.", vim.log.levels.WARN)
    return
  end
  url = url .. "/doc"
  vim.ui.open(url)
end

---@return string
function M.get_server_url()
  local ok = pcall(Client.start_server)
  if not ok then
    return ""
  end
  local port = Client.port
  if not port then
    return ""
  end
  return "http://localhost:" .. Client.port
end

return M
