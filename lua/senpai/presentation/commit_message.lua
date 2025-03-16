local Config = require("senpai.config")
local Curl = require("senpai.presentation.shared.curl")
local Spinner = require("senpai.presentation.shared.spinner")

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

--[=[@doc
  category = "api"
  name = "senpai.generate_commit_message(language)"
  desc = "AI generate conventional commit message of commitizen convention format."

  [[args]]
  name = "language"
  type = "string"
  desc = "Language of commit message"
--]=]
---@param language? string
---@return string
function M.generate_commit_message(language)
  local lang = language and language or Config.get_commit_message_language()
  local provider, provider_config = Config.get_provider()
  if not provider_config then
    vim.notify("[senpai] provider not found", vim.log.levels.WARN)
    return ""
  end
  local response = Curl.requestText("/generate-commit-message", {
    provider = provider,
    provider_config = provider_config,
    language = lang,
  })
  return response
end

--[=[@doc
  category = "api"
  name = "senpai.write_commit_message(language)"
  desc = "AI write conventional commit message of commitizen convention format."

  [[args]]
  name = "language"
  type = "string"
  desc = "Language of commit message"
--]=]
---@text
---@param language? string
---@return nil
function M.write_commit_message(language)
  local lang = language and language or Config.get_commit_message_language()
  local spinner = Spinner.new("[senpai] AI thinking")
  spinner:start()
  local commit_message = M.generate_commit_message(lang)
  spinner:stop()
  if not commit_message then
    vim.notify("[senpai] write_commit_message failed")
    return
  end
  replace_current_line(commit_message)
end

return M
