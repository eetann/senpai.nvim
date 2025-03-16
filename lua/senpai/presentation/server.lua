local Spinner = require("senpai.presentation.shared.spinner")

local M = {}

---@type vim.SystemObj?
M.job = nil

function M.start_server()
  if M.job then
    return
  end
  vim.notify("senpai!")
  local cwd = vim.fn.fnamemodify(
    vim.api.nvim_get_runtime_file("lua/senpai", false)[1],
    ":h:h"
  )
  M.job = vim.system({ "bun", "run", "src/index.ts" }, {
    cwd = cwd,
  })
end

function M:stop_server()
  if M.job then
    M.job:kill(0)
    vim.notify("[senpai] See you!")
  end
  M.job = nil
end

return M
