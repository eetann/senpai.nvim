local n = require("nui-components")
local Gap = require("nui-components.gap")
local Columns = require("nui-components.columns")
local Button = require("senpai.presentation.shared.button")
local IBlock = require("senpai.domain.i_block")
local utils = require("senpai.usecase.utils")
local Config = require("senpai.config")

---@class senpai.DiffBlock: senpai.IDiffBlock
local M = {}
M.__index = M
setmetatable(M, { __index = IBlock })

---@param row integer
---@param bufnr integer
---@return {start_line: integer, end_line: integer}|nil
local function get_codeblock_range(row, bufnr)
  local parser = vim.treesitter.get_parser(bufnr, "markdown")
  if not parser then
    return nil
  end
  -- Force parser to update
  parser:parse(true)
  local tree = parser:parse()[1]
  local root = tree:root()

  local node = root:named_descendant_for_range(row, 0, row, 0)
  while node do
    if node:type() == "fenced_code_block" then
      local start_row, _, end_row, _ = node:range()
      return { start_line = start_row, end_line = end_row - 1 }
    end
    node = node:parent()
  end
  return nil
end

---@param opts { winid:integer, bufnr:integer, row:integer|nil, path:string }
---@return senpai.DiffBlock
function M.new(opts)
  local self = setmetatable({}, M)
  self.block_type = "replace_in_file"
  local row = opts.row or vim.api.nvim_buf_line_count(opts.bufnr)
  self.row = row
  self.winid = opts.winid
  self.bufnr = opts.bufnr
  self.path = opts.path
  self.filetype = utils.get_filetype(opts.path)
  self.signal = n.create_signal({
    active_tab = "no-tab",
  })
  self.diffs = {}
  self:setup()
  utils.replace_text_at_last(
    self.bufnr,
    "filepath: " .. self.path .. "\n```\n```\n"
  )
  self:mount()

  return self
end

function M:setup_body()
  local is_tab_active = n.is_active_factory(self.signal.active_tab)
  self.body = Columns({
    flex = 1,
    children = {
      Button({
        label = "Diff",
        global_press_key = "D",
        is_active = is_tab_active("tab-diff"),
        on_press = function()
          self.signal.active_tab = "tab-diff"
        end,
        mappings = function()
          return {
            {
              mode = "n",
              key = "<S-Tab>",
              handler = function()
                utils.safe_set_current_win(
                  self.winid,
                  { row = self.row, col = 0 }
                )
              end,
            },
          }
        end,
      }),
      Gap({ size = 1 }, { zindex = 49 }),
      Button({
        label = "Replace",
        global_press_key = "R",
        is_active = is_tab_active("tab-replace"),
        on_press = function()
          self.signal.active_tab = "tab-replace"
        end,
      }),
      Gap({ size = 1 }, { zindex = 49 }),
      Button({
        label = "Search",
        global_press_key = "S",
        is_active = is_tab_active("tab-search"),
        on_press = function()
          self.signal.active_tab = "tab-search"
        end,
      }),
      Gap({ flex = 1 }, { zindex = 49 }),
      Button({
        label = "apply",
        on_press = function()
          vim.api.nvim_set_current_win(self.winid)
          vim.api.nvim_feedkeys("a", "n", false)
        end,
        mappings = function()
          return {
            {
              mode = "n",
              key = "<Tab>",
              handler = function()
                utils.safe_set_current_win(
                  self.winid,
                  { row = self.row + 1, col = 0 }
                )
              end,
            },
          }
        end,
      }),
    },
  }, {
    zindex = 50,
  })
end

function M:setup_keymaps()
  local key_tab_list = {
    { key = "D", tab = "diff" },
    { key = "R", tab = "replace" },
    { key = "S", tab = "search" },
  }
  for _, v in ipairs(key_tab_list) do
    vim.keymap.set("n", v.key, function()
      self:change_tab(v.tab)
    end, { buffer = self.bufnr })
  end
end

function M:change_tab(tab)
  local range = get_codeblock_range(self.row + 1, self.bufnr)
  if not range then
    return
  end

  local text = ""
  if tab == "diff" then
    self.signal.active_tab = "tab-diff"
    text = "```diff\n"
    local lines = {}
    for _, diff in pairs(self.diffs) do
      if diff.error ~= "" then
        table.insert(lines, "# ERROR: " .. diff.error)
      else
        table.insert(lines, diff.diff)
      end
    end
    text = text .. table.concat(lines, "\n\n")
  elseif tab == "replace" then
    self.signal.active_tab = "tab-replace"
    text = "```" .. self.filetype .. "\n"
    local lines = {}
    for _, diff in pairs(self.diffs) do
      if diff.error ~= "" then
        table.insert(lines, "// ERROR: " .. diff.error)
      else
        table.insert(lines, diff.replace)
      end
    end
    text = text .. table.concat(lines, "\n\n")
  elseif tab == "search" then
    self.signal.active_tab = "tab-search"
    text = "```" .. self.filetype .. "\n"
    local lines = {}
    for _, diff in pairs(self.diffs) do
      if diff.error ~= "" then
        table.insert(lines, "// ERROR: " .. diff.error)
      else
        table.insert(lines, diff.search)
      end
    end
    text = text .. table.concat(lines, "\n\n")
  end
  text = text .. "\n```\n"

  vim.api.nvim_buf_set_text(
    self.bufnr,
    range.start_line,
    0,
    range.end_line + 1,
    0,
    vim.split(text, "\n")
  )
end

function M:tool_result(result)
  -- Store the diffs array with all the information from server
  self.diffs = result.diffs

  if Config.chat.log_area.replace_show_type == "diff" then
    self:change_tab("diff")
  else
    self:change_tab("replace")
  end
end

---@return { label: string, action_type: string, enabled?: boolean }[]
function M:get_action_buttons()
  -- Check if there are any errors in diffs
  local has_errors = false
  for _, diff in ipairs(self.diffs) do
    if diff.error and diff.error ~= "" then
      has_errors = true
      break
    end
  end

  if has_errors then
    -- TODO: 自動でエラーを投げる？
    -- If there are errors, don't show action buttons
    return {}
  end

  return {
    { label = "Accept", action_type = "accept", enabled = true },
    { label = "Reject", action_type = "reject", enabled = true },
  }
end

---@param action_type string
---@param user_input? string
---@return { success: boolean, message: string }
function M:handle_action(action_type, user_input)
  if action_type == "accept" then
    -- Apply the diffs
    local apply_replace_file = require("senpai.usecase.apply_replace_file")
    local errors = ""

    -- Collect all replacements
    local replaces = {}
    for _, diff in ipairs(self.diffs) do
      if diff.error == "" or not diff.error then
        table.insert(replaces, {
          start_row = diff.startLine - 1,
          end_row = diff.endLine,
          lines = vim.split(diff.replace, "\n"),
        })
      end
    end

    -- Apply replacements to the file
    local file_path = vim.fn.expand(self.path)
    local bufnr = nil

    -- Find or create buffer for the file
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        local name = vim.api.nvim_buf_get_name(buf)
        if name == vim.fn.fnamemodify(file_path, ":p") then
          bufnr = buf
          break
        end
      end
    end

    if not bufnr then
      -- Create new buffer with the file
      vim.cmd("edit " .. vim.fn.fnameescape(file_path))
      bufnr = vim.api.nvim_get_current_buf()
    end

    -- Apply the replacements
    for _, replace in ipairs(replaces) do
      vim.api.nvim_buf_set_lines(
        bufnr,
        replace.start_row,
        replace.end_row,
        false,
        replace.lines
      )
    end

    -- Save the file
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd("write")
    end)

    local message = "Successfully applied changes to " .. self.path
    if user_input and user_input ~= "" then
      message = message .. "\n\n" .. user_input
    end

    return { success = true, message = message }
  elseif action_type == "reject" then
    local message = "Rejected changes to " .. self.path
    if user_input and user_input ~= "" then
      message = message .. "\n\n" .. user_input
    end
    return { success = true, message = message }
  else
    return { success = false, message = "Unknown action type: " .. action_type }
  end
end

-- local block = M.new({
--   winid = vim.api.nvim_get_current_win(),
--   bufnr = vim.api.nvim_get_current_buf(),
--   row = 2,
-- })
return M
