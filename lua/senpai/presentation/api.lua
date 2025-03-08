local Config = require("senpai.config")

local M = {}

local function wait_for_setup()
  vim.fn["denops#plugin#wait"]("senpai")
end

local function replace_current_line(response)
  local line_number = vim.api.nvim_win_get_cursor(0)[1] - 1
  vim.api.nvim_buf_set_lines(
    0,
    line_number,
    line_number + 1,
    false,
    vim.split(response, "\n")
  )
end

function M.hello()
  local provider = Config.provider
  local provider_opts = Config.providers["openai"]
  wait_for_setup()
  local response = vim.fn["denops#request"]("senpai", "hello", {})
  vim.notify(response)
end

function M.generate_commit_message()
  local provider = Config.provider
  local provider_config = Config.providers["openai"]
  wait_for_setup()
  local response = vim.fn["denops#request"](
    "senpai",
    "generateCommitMessage",
    { provider, provider_config }
  )
  return response
end

---@tag senpai-write-commit-message
---@text
--- AI write conventional commit message of commitizen convention format.
function M.write_commit_message()
  local commit_message = M.generate_commit_message()
  if not commit_message then
    vim.notify("[senpai] write_commit_message failed")
    return
  end
  replace_current_line(commit_message)
end

return M
