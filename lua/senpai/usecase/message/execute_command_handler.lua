local utils = require("senpai.usecase.utils")

---@class Senpai.message.ExecuteCommandHandler: Senpai.message.IAssistantHandler
---@field terminal_block senpai.ITerminalBlock|nil
local M = {}
M.__index = M
M.tag_name = "execute_command"

function M.new(chat)
  local self = setmetatable({}, M)
  self.chat = chat
  self.current_content = ""
  self.current_tag = nil
  self.handlers = {
    ["<command>.*</command>"] = self.command_tag,
  }

  self.terminal_block = nil

  return self
end

function M:start_tag()
  utils.replace_text_at_last(self.chat.log_area.bufnr, "\n")
  self.current_tag = "execute_command"
  local row = vim.api.nvim_buf_line_count(self.chat.log_area.bufnr)
  self.terminal_block = self.chat:add_terminal_block(row - 1)
end

function M:command_tag(_, line)
  self.terminal_block.command = line:match("<command>(.-)</command>")
  self.current_tag = nil
end

function M:end_tag()
  local text = "```sh\n" .. self.terminal_block.command .. "\n```\n"
  self:render_base(text)
  self.current_tag = nil
end

function M:content_line() end

---@param text string
function M:render_base(text)
  utils.set_text_at_last(self.chat.log_area.bufnr, text)
end

return M
