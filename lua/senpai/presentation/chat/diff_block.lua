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
---@return {start_line: integer, end_line: integer}|nil
local function get_codeblock_range(row)
  local parser = vim.treesitter.get_parser(0, "markdown")
  if not parser then
    return nil
  end
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
  self.block_type = "diff"
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

  local range = get_codeblock_range(self.row + 1)
  if not range then
    vim.print(" not range")
    return
  end
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

-- local block = M.new({
--   winid = vim.api.nvim_get_current_win(),
--   bufnr = vim.api.nvim_get_current_buf(),
--   row = 2,
-- })
return M
