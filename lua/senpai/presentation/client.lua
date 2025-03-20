local M = {}

---@type vim.SystemObj?
M.job = nil

---@type number?
M.port = nil

---start server
---@param in_setup? boolean Flag to prevent sleep if called from the plugin's setup function
function M.start_server(in_setup)
  if M.job then
    return
  end

  local cwd = vim.fn.fnamemodify(
    vim.api.nvim_get_runtime_file("lua/senpai", false)[1],
    ":h:h"
  )

  local max_attempts = 10
  local attempts = 0

  local function try_start_server()
    attempts = attempts + 1
    if attempts > max_attempts then
      vim.notify("[senpai] Server startup failed.", vim.log.levels.ERROR)
      return
    end
    M.port = math.random(1024, 49151)

    M.job = vim.system(
      { "bun", "run", "src/index.ts", "--port", tostring(M.port) },
      {
        cwd = cwd,
        stdout = vim.schedule_wrap(function(_, data)
          --
        end),
      },
      function(obj)
        if obj.code ~= 0 and obj.stderr:find("EADDRINUSE") then
          M.job = nil
          vim.schedule(try_start_server)
          return
        end
        M.job = nil
        M.port = nil
      end
    )
    if not in_setup then
      vim.cmd("sleep 1000ms")
    end
  end

  math.randomseed(os.time())
  try_start_server()
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
