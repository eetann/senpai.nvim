local M = {}

M.hello = function()
  vim.cmd('echo denops#request("senpai", "hello", [])')
end

return M
