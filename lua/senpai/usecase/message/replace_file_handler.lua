local utils = require("senpai.usecase.utils")
local Config = require("senpai.config")

local M = {}
M.__index = M
M.tag_name = "replace_file"

local function get_diff_text(search, replace)
  local tmp1 = os.tmpname()
  local tmp2 = os.tmpname()

  local f1 = assert(io.open(tmp1, "w"))
  f1:write(search)
  f1:close()

  local f2 = assert(io.open(tmp2, "w"))
  f2:write(replace)
  f2:close()

  local result = vim.system({ "git", "diff", "--no-index", tmp1, tmp2 }):wait()
  local lines = vim.split(result.stdout, "\n")
  local text = ""
  if #lines >= 6 then
    text = table.concat({ unpack(lines, 6) }, "\n")
  end

  os.remove(tmp1)
  os.remove(tmp2)
  return text
end

function M.new(chat)
  local self = setmetatable({}, M)
  self.chat = chat
  self.current_content = ""
  self.current_tag = nil
  self.handlers = {
    ["<path>.*</path>"] = self.path_tag,
    ["<search>"] = self.start_search_tag,
    ["</search>"] = self.end_search_tag,
    ["<replace>"] = self.start_replace_tag,
    ["</replace>"] = self.end_replace_tag,
  }

  self.diff_popup = nil

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
  self.diff_popup = self.chat:add_diff_popup(row - 1, path)
  self.diff_popup.path = path
  self.diff_popup:mount()
end

function M:start_search_tag()
  self.current_tag = "search"
  self.diff_popup:change_tab("search")
  self.current_content = ""
end

function M:end_search_tag(chunk)
  self.current_content = self.current_content .. chunk
  self.diff_popup.search_text = self.current_content:gsub("\n</search>\n?", "")
  self.current_tag = nil
end

function M:start_replace_tag()
  self.current_tag = "replace"
  self.diff_popup:change_tab("replace")
  self.current_content = ""
end

function M:end_replace_tag(chunk)
  self.current_content = self.current_content .. chunk
  self.diff_popup.replace_text =
    self.current_content:gsub("\n</replace>\n?", "")
  self.current_tag = nil
end

function M:end_tag()
  self.diff_popup.diff_text = get_diff_text(
    self.diff_popup.search_text,
    self.diff_popup.replace_text
  ) or ""
  local text = ""
  if Config.chat.log_area.replace_show_type == "diff" then
    self.diff_popup:change_tab("diff")
    text = "```diff\n" .. self.diff_popup.diff_text
  else
    self.diff_popup:change_tab("replace")
    text = "```"
      .. self.diff_popup.filetype
      .. "\n"
      .. self.diff_popup.replace_text
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
