local utils = require("senpai.usecase.utils")

---@class senpai.message.assistant.replace_file_current: senpai.XML.replace_file
---@field id string
---@field tag? string
---@field start_line number

---@class senpai.message.assistant
---@field chat senpai.IChatWindow
---@field replace_file_current senpai.message.assistant.replace_file_current
---@field current_content string
---@field line string
---@field namespace integer
local M = {}
M.__index = M

---@param chat senpai.IChatWindow
---@return senpai.message.assistant
function M.new(chat)
  local self = setmetatable({}, M)
  self.chat = chat
  self.replace_file_current = {
    id = "",
    path = "",
    search = {},
    replace = {},
    tag = nil,
    start_line = 0,
  }
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
  if self.replace_file_current.id == "" then
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
  end

  if self.replace_file_current.tag then
    self:process_content_line(chunk)
  end
end

function M:process_start_replace_file()
  local id = utils.create_random_id(12)
  utils.replace_text_at_last(
    self.chat.log_area.bufnr,
    '\n<SenpaiReplaceFile id="' .. id .. '">\n\n'
  )
  local start_line = vim.fn.line("$", self.chat.log_area.winid) - 2
  self.replace_file_current = {
    id = id,
    path = "",
    search = {},
    replace = {},
    start_line = start_line,
  }
  vim.api.nvim_buf_set_extmark(
    self.chat.log_area.bufnr,
    self.namespace,
    start_line - 1,
    0,
    {
      sign_text = "󰬲",
      sign_hl_group = "DiagnosticInfo",
      virt_text = { { "Replace File" } },
      virt_text_pos = "inline",
    }
  )
end

function M:process_path_tag()
  local path = utils.get_relative_path(self.line:match("<path>(.-)</path>"))
    or ""
  self.replace_file_current.path = path
  self.replace_file_current.tag = nil
  self.current_content = ""
  self.line = ""
  utils.replace_text_at_last(
    self.chat.log_area.bufnr,
    "filepath: " .. path .. "\n"
  )
end

function M:process_start_search_tag()
  self.replace_file_current.tag = "search"
  self.current_content = ""
  utils.replace_text_at_last(self.chat.log_area.bufnr, "")
  -- TODO: 検索スピナーの開始
end

function M:process_end_search_tag(chunk)
  self.current_content = self.current_content .. chunk
  self.replace_file_current.search =
    vim.split(self.current_content:gsub("\n</search>\n?", ""), "\n")
  self.replace_file_current.tag = nil
  utils.replace_text_at_last(self.chat.log_area.bufnr, "")
  -- TODO: 検索スピナーの終了
  self.line = ""
end

function M:process_start_replace_tag()
  self.replace_file_current.tag = "replace"
  self.current_content = ""
  local filetype = utils.get_filetype(self.replace_file_current.path)
  utils.replace_text_at_last(
    self.chat.log_area.bufnr,
    "```" .. filetype .. "\n"
  )
  self.line = ""
end

function M:process_end_replace_tag()
  self.replace_file_current.replace =
    vim.split(self.current_content:gsub("\n$", ""), "\n")
  self.replace_file_current.tag = nil
  utils.replace_text_at_last(self.chat.log_area.bufnr, "```" .. "\n")
end

function M:process_end_replace_file()
  self.chat.replace_file_results[self.replace_file_current.id] = vim.deepcopy({
    path = self.replace_file_current.path,
    search = self.replace_file_current.search,
    replace = self.replace_file_current.replace,
  })
  utils.replace_text_at_last(
    self.chat.log_area.bufnr,
    "\n</SenpaiReplaceFile>\n"
  )
  vim.api.nvim_buf_set_extmark(
    self.chat.log_area.bufnr,
    self.namespace,
    self.replace_file_current.start_line - 1,
    0,
    {
      virt_text = { { "apply [a]" } },
      virt_text_pos = "right_align",
    }
  )

  local end_index = vim.fn.line("$", self.chat.log_area.winid) - 3
  for i = self.replace_file_current.start_line, end_index do
    vim.api.nvim_buf_set_extmark(
      self.chat.log_area.bufnr,
      self.namespace,
      i, -- 0-based
      0,
      {
        sign_text = "▕",
        sign_hl_group = "DiagnosticVirtualInfo",
      }
    )
  end

  self.replace_file_current =
    { id = "", path = "", search = {}, replace = {}, start_line = 0 }
  self.replace_file_current.tag = nil
end

function M:process_content_line(chunk)
  self.current_content = self.current_content .. chunk
  if self.replace_file_current.tag ~= "search" then
    self:render_base(chunk)
  end
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
