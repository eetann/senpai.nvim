local Config = require("senpai.config")

local M = {}

---@type vim.SystemObj?
M.job = nil

---@type number?
M.port = nil

local function wait_to_setup_server()
  -- TODO: vim.wait?
  for _ = 1, 50 do
    local result =
      vim.system({ "curl", "-s", "http://localhost:" .. M.port }):wait()
    if result.code == 0 then
      return
    end
    vim.cmd("sleep 200ms")
  end
  error("Could not connect to internal server")
end

---start server
function M.start_server()
  if M.job then
    wait_to_setup_server()
    return
  end

  local cwd = vim.fn.fnamemodify(
    vim.api.nvim_get_runtime_file("lua/senpai", false)[1],
    ":h:h"
  )
  local mcp = vim.json.encode(Config.mcp.servers or {})

  local max_attempts = 10
  local attempts = 0

  local function try_start_server()
    attempts = attempts + 1
    if attempts > max_attempts then
      error("Server startup failed")
      return
    end
    M.port = math.random(1024, 49151)

    M.job = vim.system({
      "bun",
      "run",
      "src/index.ts",
      "--cwd",
      vim.fn.getcwd(),
      "--port",
      tostring(M.port),
      "--mcp",
      mcp,
    }, {
      cwd = cwd,
      stdout = vim.schedule_wrap(function(_, data)
        if Config.internal_log then
          Config.internal_log:write(data)
        end
      end),
      stderr = vim.schedule_wrap(function(_, data)
        if Config.internal_log then
          Config.internal_log:write(data)
        end
      end),
    }, function(obj)
      if obj.code ~= 0 and obj.stderr:find("EADDRINUSE") then
        M.job = nil
        vim.schedule(try_start_server)
        return
      end
      M.job = nil
      M.port = nil
    end)
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
