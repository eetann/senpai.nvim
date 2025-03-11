local M = {}

function M.wait_for_setup()
  return vim.fn["denops#plugin#wait"]("senpai")
end

function M.wait_async_for_setup(callback)
  vim.fn["denops#plugin#wait_async"]("senpai", callback)
end

return M
