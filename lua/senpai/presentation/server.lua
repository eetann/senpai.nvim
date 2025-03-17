local Config = require("senpai.config")

local M = {}

---@type vim.SystemObj?
M.job = nil

function M.start_server()
  if M.job then
    return
  end
  local cwd = vim.fn.fnamemodify(
    vim.api.nvim_get_runtime_file("lua/senpai", false)[1],
    ":h:h"
  )
  M.job = vim.system(
    { "bun", "run", "src/index.ts", "--port", tostring(Config.port) },
    {
      cwd = cwd,
    }
  )
end

function M:stop_server()
  if M.job then
    M.job:kill(0)
    vim.notify("[senpai] See you!")
  end
  M.job = nil
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  pattern = "*",
  callback = function()
    local pid = M.job.pid
    if M.job then
      M.job:kill(0)
      vim.uv.kill(pid, 9)
    end
  end,
})
return M
