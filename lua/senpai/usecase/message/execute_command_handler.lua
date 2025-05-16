local utils = require("senpai.usecase.utils")
local Config = require("senpai.config")

---@class Senpai.message.ExecuteCommandHandler: Senpai.message.IAssistantHandler
local M = {}
M.__index = M
M.tag_name = "execute_command"

function M.new(chat)
  local self = setmetatable({}, M)
  self.chat = chat
  self.current_content = ""
  self.current_tag = nil
  self.handlers = {
    ["<replace>"] = self.start_replace_tag,
    ["</replace>"] = self.end_replace_tag,
  }

  self.diff_block = nil

  return self
end

function M:start_tag()
  utils.replace_text_at_last(self.chat.log_area.bufnr, "\n")
  self.current_tag = "replace_file"
end

function M:path_tag(_, line)
  local path = utils.get_relative_path(line:match("<path>(.-)</path>")) or ""
  self.current_content = ""
  utils.replace_text_at_last(
    self.chat.log_area.bufnr,
    "filepath: " .. path .. "\n"
  )
  local row = vim.api.nvim_buf_line_count(self.chat.log_area.bufnr)
  self.diff_block = self.chat:add_diff_block(row - 1, path)
  self.diff_block.path = path
  self.diff_block:mount()
end

function M:start_search_tag()
  self.current_tag = "search"
  self.diff_block:change_tab("search")
  self.current_content = ""
end

function M:end_search_tag(chunk)
  self.current_content = self.current_content .. chunk
  self.diff_block.search_text = self.current_content:gsub("\n</search>\n?", "")
  self.current_tag = nil
end

function M:start_replace_tag()
  self.current_tag = "replace"
  self.diff_block:change_tab("replace")
  self.current_content = ""
end

function M:end_replace_tag(chunk)
  self.current_content = self.current_content .. chunk
  self.diff_block.replace_text =
    self.current_content:gsub("\n</replace>\n?", "")
  self.current_tag = nil
end

function M:end_tag()
  self.diff_block.diff_text = get_diff_text(
    self.diff_block.search_text,
    self.diff_block.replace_text
  ) or ""
  local text = ""
  if Config.chat.log_area.replace_show_type == "diff" then
    self.diff_block:change_tab("diff")
    text = "```diff\n" .. self.diff_block.diff_text
  else
    self.diff_block:change_tab("replace")
    text = "```"
      .. self.diff_block.filetype
      .. "\n"
      .. self.diff_block.replace_text
  end
  text = text .. "\n```\n"
  self:render_base(text)

  self.current_tag = nil
end

function M:content_line(chunk)
  self.current_content = self.current_content .. chunk
end

---@param text string
function M:render_base(text)
  utils.set_text_at_last(self.chat.log_area.bufnr, text)
end

return M
