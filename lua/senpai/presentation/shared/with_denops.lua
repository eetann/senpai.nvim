local M = {}

function M.wait_for_setup()
  local timeout = 10 * 1000
  local elapsed = 0
  local status = vim.fn["denops#plugin#is_loaded"]("senpai")

  while status ~= 1 and elapsed < timeout do
    vim.cmd("sleep 300m")
    elapsed = elapsed + 300
    status = vim.fn["denops#plugin#is_loaded"]("senpai")
  end

  return vim.fn["denops#plugin#wait"]("senpai")
end

function M.wait_async_for_setup(callback)
  vim.fn["denops#plugin#wait_async"]("senpai", callback)
end

return M
