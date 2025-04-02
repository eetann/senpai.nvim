local RequestHandler = require("senpai.usecase.request.request_handler")
local Popup = require("nui.popup")
local M = {}

function M.execute()
  local response = RequestHandler.request_without_callback({
    method = "get",
    route = "/mcp",
  })
  if response.exit ~= 0 then
    vim.notify("[senpai] failed to get MCP Tools ", vim.log.levels.WARN)
    return {}
  end
  local ok, tools = pcall(vim.json.decode, response.body)
  if not ok or type(tools) ~= "table" then
    vim.notify("[senpai] failed to get MCP Tools ", vim.log.levels.WARN)
    return {}
  end
  local content = ""
  if
    (type(tools) == "table" and next(tools) == nil)
    or not tools
    or tools == ""
  then
    content = "*No MCP Tools*"
  else
    content = vim.inspect(tools)
  end

  local keys = { "<ESC>", "q", "<C-c>", "<CR>" }
  local popup = Popup({
    relative = "editor",
    position = "50%",
    size = {
      width = "40%",
      height = "80%",
    },
    border = {
      padding = {
        top = 1,
        bottom = 1,
        left = 1,
        right = 1,
      },
      style = "rounded",
      text = {
        top = "MCP Tools (" .. table.concat(keys, "/") .. "...close)",
        top_align = "center",
      },
    },
    buf_options = {
      filetype = "markdown",
    },
    enter = true,
  })
  popup:mount()
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, vim.split(content, "\n"))
  vim.bo[popup.bufnr].modifiable = false
  vim.bo[popup.bufnr].readonly = true
  for _, key in pairs(keys) do
    popup:map("n", key, function()
      popup:unmount()
    end)
  end
end

return M
