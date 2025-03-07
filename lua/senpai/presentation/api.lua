local M = {}

M.hello = function()
  local response = vim.fn["denops#request"]("senpai", "hello", {})
  vim.notify(response)
end

return M
