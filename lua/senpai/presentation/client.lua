local M = {}

---@type vim.SystemObj?
M.job = nil

---@type number?
M.port = nil

local function get_port(err, data)
  if err or not data then
    vim.notify(
      "[senpai] Server startup failed. Please try again.",
      vim.log.levels.ERROR
    )
    return
  end
  local port = tonumber(string.match(data, "localhost:(%d+)"))
  if not port then
    vim.notify(
      "[senpai] Server startup failed. Please try again.",
      vim.log.levels.ERROR
    )
    return
  end
  M.port = port
end

function M.start_server()
  if M.job then
    return
  end
  local cwd = vim.fn.fnamemodify(
    vim.api.nvim_get_runtime_file("lua/senpai", false)[1],
    ":h:h"
  )
  M.job = vim.system({ "bun", "run", "src/index.ts" }, {
    cwd = cwd,
    stdout = vim.schedule_wrap(function(err, data)
      get_port(err, data)
    end),
  }, function()
    M.job = nil
    M.port = nil
  end)
end

local function stop_server()
  local pid = M.job.pid
  if M.job then
    M.job:kill(0)
    vim.uv.kill(pid, 9)
  end
  M.job = nil
  M.port = nil
end

function M.shutdown()
  stop_server()
  vim.notify("[senpai] See you!")
end

function M.get_pid()
  vim.print("pid is " .. M.job.pid)
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  pattern = "*",
  callback = function()
    stop_server()
  end,
})
return M
