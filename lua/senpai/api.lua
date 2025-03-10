local Config = require("senpai.config")

local M = {}

local function wait_for_setup()
  vim.fn["denops#plugin#wait"]("senpai")
end

local function wait_async_for_setup(callback)
  vim.fn["denops#plugin#wait_async"]("senpai", callback)
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
  local provider_opts = Config.providers[provider]
  wait_for_setup()
  local response = vim.fn["denops#request"]("senpai", "hello", {})
  vim.notify(response)
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
  wait_for_setup()
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
  local commit_message = M.generate_commit_message(lang)
  if not commit_message then
    vim.notify("[senpai] write_commit_message failed")
    return
  end
  replace_current_line(commit_message)
end

function M.summarize(text)
  local provider, provider_config = Config.get_provider()
  if not provider_config then
    vim.notify("[senpai] provider not found", vim.log.levels.WARN)
    return ""
  end
  wait_async_for_setup(function()
    vim.fn["denops#notify"]("senpai", "summarize", {
      {
        provider = provider,
        provider_config = provider_config,
        text = text,
      },
    })
  end)
end

return M
