local utils = require("senpai.usecase.utils")

---@class senpai.message.assistant.replace_file_current: senpai.XML.replace_file
---@field id string
---@field tag? string
---@field start_line number

---@class senpai.message.assistant
---@field chat senpai.IChatWindow
---@field replace_file_current senpai.message.assistant.replace_file_current
---@field diff_popup senpai.IDiffPopup|nil
---@field current_content string
---@field line string
---@field namespace integer
local M = {}
M.__index = M

local function diff_temp_files(bufnr, search, replace)
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
  if #lines >= 6 then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { unpack(lines, 6) })
  end

  os.remove(tmp1)
  os.remove(tmp2)
end

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
  elseif lower_line:match("</replace_file>") then
    self:process_end_replace_file()
  end

  if self.replace_file_current.tag then
    self:process_content_line(chunk, is_lastline)
  end
end

function M:process_start_replace_file()
  local id = utils.create_random_id(12)

  utils.replace_text_at_last(self.chat.log_area.bufnr, "\n")
  local start_line = vim.fn.line("$", self.chat.log_area.winid) - 2
  self.replace_file_current = {
    id = id,
    path = "",
    search = {},
    replace = {},
    start_line = start_line,
  }
  -- vim.api.nvim_buf_set_extmark(
  --   self.chat.log_area.bufnr,
  --   self.namespace,
  --   start_line - 1,
  --   0,
  --   {
  --     sign_text = "󰬲",
  --     sign_hl_group = "DiagnosticInfo",
  --     -- virt_text = { { "Replace File" } },
  --     -- virt_text_pos = "inline",
  --   }
  -- )
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
    "filepath: " .. path .. "\n\n"
  )
  local row = vim.api.nvim_buf_line_count(self.chat.log_area.bufnr)
  local filetype = utils.get_filetype(path)
  self.diff_popup = self.chat:add_diff_popup(row - 1, filetype)
  self.diff_popup:mount()
end

function M:process_start_search_tag()
  self.replace_file_current.tag = "search"
  self.diff_popup:change_tab("search")
  self.current_content = ""
end

function M:process_end_search_tag(chunk)
  vim.api.nvim_buf_set_lines(
    self.diff_popup.tabs.search.bufnr,
    -2,
    -1,
    false,
    {}
  )
  self.current_content = self.current_content .. chunk
  self.replace_file_current.search =
    vim.split(self.current_content:gsub("\n</search>\n?", ""), "\n")
  self.replace_file_current.tag = nil
  self.line = ""
end

function M:process_start_replace_tag()
  self.replace_file_current.tag = "replace"
  self.diff_popup:change_tab("replace")
  self.current_content = ""
  self.line = ""
end

function M:process_end_replace_tag(chunk)
  vim.api.nvim_buf_set_lines(
    self.diff_popup.tabs.replace.bufnr,
    -2,
    -1,
    false,
    {}
  )
  self.current_content = self.current_content .. chunk
  self.replace_file_current.replace =
    vim.split(self.current_content:gsub("\n</replace>\n?", ""), "\n")
  self.replace_file_current.tag = nil
end

function M:process_end_replace_file()
  self.chat.replace_file_results[self.replace_file_current.id] = vim.deepcopy({
    path = self.replace_file_current.path,
    search = self.replace_file_current.search,
    replace = self.replace_file_current.replace,
  })
  diff_temp_files(
    self.diff_popup.tabs.diff.bufnr,
    table.concat(self.replace_file_current.search, "\n"),
    table.concat(self.replace_file_current.replace, "\n")
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

  self.replace_file_current =
    { id = "", path = "", search = {}, replace = {}, start_line = 0 }
  self.replace_file_current.tag = nil
end

function M:process_content_line(chunk, is_lastline)
  self.current_content = self.current_content .. chunk
  if is_lastline then
    return
  end
  if self.replace_file_current.tag == "search" then
    utils.set_text_at_last(self.diff_popup.tabs.search.bufnr, self.line .. "\n")
  elseif self.replace_file_current.tag == "replace" then
    utils.set_text_at_last(
      self.diff_popup.tabs.replace.bufnr,
      self.line .. "\n"
    )
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
