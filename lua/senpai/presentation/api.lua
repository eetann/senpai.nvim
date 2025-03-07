local M = {}

local function wait_async(callback)
  vim.fn["denops#plugin#wait_async"]("senpai", callback)
end

M.hello = function()
  wait_async(function()
    local response = vim.fn["denops#request"]("senpai", "hello", {})
    vim.notify(response)
  end)
end

M.generate_commit_message = function()
  wait_async(function()
    local response =
      vim.fn["denops#request"]("senpai", "generateCommitMessage", {})
    return response
  end)
end

return M
