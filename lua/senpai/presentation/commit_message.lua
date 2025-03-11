local Config = require("senpai.config")
local WithDenops = require("senpai.presentation.shared.with_denops")

local M = {}

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

---@tag senpai-generate-commit-message
---@param language? string
---@return string
function M.generate_commit_message(language)
  local lang = language and language or Config.get_commit_message_language()
  local provider, provider_config = Config.get_provider()
  if not provider_config then
    vim.notify("[senpai] provider not found", vim.log.levels.WARN)
    return ""
  end
  local is_success_load = WithDenops.wait_for_setup()
  if is_success_load ~= 0 then
    vim.notify("[senpai] error code: " .. is_success_load, vim.log.levels.WARN)
    vim.notify("[senpai] plugin not loaded", vim.log.levels.WARN)
    return ""
  end
  local response = vim.fn["denops#request"]("senpai", "generateCommitMessage", {
    {
      provider = provider,
      provider_config = provider_config,
      language = lang,
    },
  })
  return response
end

---@tag senpai-write-commit-message
---@text
--- AI write conventional commit message of commitizen convention format.
---@param language? string
---@return nil
function M.write_commit_message(language)
  local lang = language and language or Config.get_commit_message_language()
  WithDenops.wait_async_for_setup(function()
    local commit_message = M.generate_commit_message(lang)
    if not commit_message then
      vim.notify("[senpai] write_commit_message failed")
      return
    end
    replace_current_line(commit_message)
  end)
end

return M
