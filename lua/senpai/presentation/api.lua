local M = {}

M.hello = function()
  vim.fn["denops#request"]("senpai", "hello", {})
end

return M
