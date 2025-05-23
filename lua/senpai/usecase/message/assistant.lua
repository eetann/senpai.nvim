local utils = require("senpai.usecase.utils")
local Config = require("senpai.config")

---@class senpai.message.assistant
---@field chat senpai.IChatWindow
---@field current_xml "replace_file"|nil
---@field current_tag string|nil
---@field diff_popup senpai.IDiffPopup|nil
---@field current_content string
---@field line string
---@field namespace integer
local M = {}
M.__index = M

---@param search string
---@param replace string
---@return string
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

---@param chat senpai.IChatWindow
---@return senpai.message.assistant
function M.new(chat)
  local self = setmetatable({}, M)
  self.chat = chat
  self.current_content = ""
  self.line = ""
  self.namespace = vim.api.nvim_create_namespace("sepnai-chat")
  return self
end

---@param text string
function M:render_base(text)
  utils.set_text_at_last(self.chat.log_area.bufnr, text)
end

---@param text string
function M:process_chunk(text)
  local lines = vim.split(text, "\n", { plain = true })
  local length = #lines
  for i = 1, length do
    local chunk = lines[i]
    self.line = self.line .. chunk
    local is_lastline = i == length
    -- chunk: `foo` newline=0
    -- chunk: `foo\nbar` newline=1,0
    -- chunk: `foo\n\nbar` newline=1,1,0
    if length > 1 and not is_lastline then
      chunk = chunk .. "\n"
    end
    -- 0:"...</path>"
    -- 0:"\n</search>"
    -- ---
    -- 0:"<replace>"
    -- 0:"local utils"
    self:process_line(chunk, is_lastline)
    if not is_lastline then
      self.line = ""
    end
  end
end

---@param chunk string
---@param is_lastline boolean
function M:process_line(chunk, is_lastline)
  local lower_line = string.lower(self.line)
  if not self.current_xml then
    if lower_line:match("<replace_file>") then
      self:process_start_replace_file()
    else
      self:render_base(chunk)
    end
    return
  end

  if not is_lastline then
    local tag_handlers = {
      ["</replace_file>"] = self.process_end_replace_file,
      ["<path>.*</path>"] = self.process_path_tag,
      ["<search>"] = self.process_start_search_tag,
      ["</search>"] = self.process_end_search_tag,
      ["<replace>"] = self.process_start_replace_tag,
      ["</replace>"] = self.process_end_replace_tag,
    }

    for pattern, handler in pairs(tag_handlers) do
      if lower_line:match(pattern) then
        handler(self, chunk)
        return
      end
    end
  elseif lower_line:match("</replace_file>") then
    self:process_end_replace_file()
  end

  if self.current_tag then
    self:process_content_line(chunk)
  end
end

function M:process_start_replace_file()
  utils.replace_text_at_last(self.chat.log_area.bufnr, "\n")
  self.current_xml = "replace_file"
  self.current_tag = "replace_file"
end

function M:process_path_tag()
  local path = utils.get_relative_path(self.line:match("<path>(.-)</path>"))
    or ""
  self.current_content = ""
  self.line = ""
  utils.replace_text_at_last(
    self.chat.log_area.bufnr,
    "filepath: " .. path .. "\n"
  )
  local row = vim.api.nvim_buf_line_count(self.chat.log_area.bufnr)
  self.diff_popup = self.chat:add_diff_popup(row - 1, path)
  self.diff_popup.path = path
  self.diff_popup:mount()
end

function M:process_start_search_tag()
  self.current_tag = "search"
  self.diff_popup:change_tab("search")
  self.current_content = ""
end

function M:process_end_search_tag(chunk)
  self.current_content = self.current_content .. chunk
  self.diff_popup.search_text = self.current_content:gsub("\n</search>\n?", "")
  self.current_tag = nil
  self.line = ""
end

function M:process_start_replace_tag()
  self.current_tag = "replace"
  self.diff_popup:change_tab("replace")
  self.current_content = ""
  self.line = ""
end

function M:process_end_replace_tag(chunk)
  self.current_content = self.current_content .. chunk
  self.diff_popup.replace_text =
    self.current_content:gsub("\n</replace>\n?", "")
  self.current_tag = nil
end

function M:process_end_replace_file()
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

  self.current_xml = nil
  self.current_tag = nil
end

function M:process_content_line(chunk)
  self.current_content = self.current_content .. chunk
end

---@param message senpai.chat.message.assistant
function M:render_from_memory(message)
  local content = message.content
  if type(content) == "string" then
    self:process_chunk(content)
    return
  end
  -- content is `senpai.chat.message.assistant.part[]`
  local text = ""
  for _, part in pairs(content) do
    if part.type == "text" then
      text = text .. "\n" .. part.text
    elseif part.type == "reasoning" then
      text = text .. "\n" .. part.text
    end
  end
  self:process_chunk(text)
end

---@param part senpai.data_stream_protocol type = "0"
function M:render_from_response(part)
  self:process_chunk(part.content --[[@as string]])
end

return M
