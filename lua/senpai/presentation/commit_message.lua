local Config = require("senpai.config")
local RequestHandler = require("senpai.presentation.shared.request_handler")
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
  name = "generate_commit_message"
  desc = """
```lua
senpai.generate_commit_message(language)
```
AI generate conventional commit message of commitizen convention format.
"""

  [[args]]
  name = "language"
  type = "string"
  desc = "Language of commit message"
  [[args]]
  name = "callback"
  type = "senpai.RequestHandler.callback"
  desc = "Function to be processed using the response"
--]=]
---@param language string
---@param callback senpai.RequestHandler.callback_fun
---@param finish_callback fun():nil For example, stopping a spinner.
---@return nil
function M.generate_commit_message(language, callback, finish_callback)
  local provider = Config.get_provider()
  if not provider then
    return
  end
  RequestHandler.request({
    method = "post",
    route = "/agent/generate-commit-message",
    body = {
      provider = provider,
      language = language,
    },
    callback = callback,
  }, finish_callback)
end

--[=[@doc
  category = "api"
  name = "write_commit_message"
  desc = """
```lua
senpai.write_commit_message(language)
```
AI write conventional commit message of commitizen convention format.
"""

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
  M.generate_commit_message(lang, function(response)
    if response.exit ~= 0 then
      vim.notify("[senpai] write_commit_message failed")
      return
    end
    replace_current_line(response.body)
  end, function()
    spinner:stop()
  end)
end

return M
