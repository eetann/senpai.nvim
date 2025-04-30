local n = require("nui-components")

local FLOAT_WIDTH_MARGIN = 2 + 7 -- border(L/R) + signcolumn

---@class senpai.DiffBlock
---@field bufnr integer
---@field signal { active_tab: NuiSignal<string> }
---@field tabs {diff: NuiBuffer, replace: NuiBuffer, search: NuiBuffer}
---@field body NuiComponent
---@field renderer NuiRenderer
local M = {}
M.__index = M

---@return NuiBuffer
local function create_buffer_component()
  local bufnr = vim.api.nvim_create_buf(false, true)
  local buffer_component = n.buffer({
    buf = bufnr,
    flex = 1,
    border_style = "rounded",
  })
  return buffer_component
end

---@param opts { winid:integer ,bufnr:integer, row:integer, height:integer }
---@return senpai.DiffBlock
function M.new(opts)
  local self = setmetatable({}, M)
  self.bufnr = opts.bufnr

  self.signal = n.create_signal({
    active_tab = "tab-diff",
  })

  local is_tab_active = n.is_active_factory(self.signal.active_tab)

  self.tabs = {
    diff = create_buffer_component(),
    replace = create_buffer_component(),
    search = create_buffer_component(),
  }

  self.body = n.tabs(
    {
      active_tab = self.signal.active_tab,
    },
    n.columns(
      {
        flex = 0,
      },
      n.button({
        label = "(gD) Diff ",
        global_press_key = "gD",
        is_active = is_tab_active("tab-diff"),
        on_press = function()
          self.signal.active_tab = "tab-diff"
        end,
      }),
      n.gap(1),
      n.button({
        label = "(gR) Replace ",
        global_press_key = "gR",
        is_active = is_tab_active("tab-replace"),
        on_press = function()
          self.signal.active_tab = "tab-replace"
        end,
      }),
      n.gap(1),
      n.button({
        label = "(gS) Search ",
        global_press_key = "gS",
        is_active = is_tab_active("tab-search"),
        on_press = function()
          self.signal.active_tab = "tab-search"
        end,
      }),
      n.gap({ flex = 5 })
    ),
    n.tab({ id = "tab-diff" }, self.tabs.diff),
    n.tab({ id = "tab-replace" }, self.tabs.replace),
    n.tab({ id = "tab-search" }, self.tabs.search)
  )

  local width = vim.api.nvim_win_get_width(opts.winid) - FLOAT_WIDTH_MARGIN
  if width < 5 then
    width = 5
  end
  self.renderer = n.create_renderer({
    bufnr = self.bufnr,
    relative = {
      type = "buf",
      position = {
        row = opts.row - 1,
        col = 0,
      },
    },
    size = {
      width = width,
      height = opts.height,
    },
    position = 1,
    width = 60,
    height = 30,
    keymap = {
      close = nil,
    },
  })

  vim.api.nvim_set_hl(0, "NuiComponentsButton", { link = "@comment" })
  vim.api.nvim_set_hl(
    0,
    "NuiComponentsButtonActive",
    { link = "@markup.heading", bold = true }
  )

  self.renderer:add_mappings({
    {
      mode = "n",
      key = "q",
      handler = function()
        self:close()
      end,
    },
  })

  return self
end

function M:render()
  self.renderer:render(self.body)
end

function M:close()
  self.renderer:close()
end

---@param tab_name "diff" | "replace" | "search"
---@param lines string[]
function M:set_buffer_content(tab_name, lines)
  local buffer_component = self.tabs[tab_name]
  vim.api.nvim_buf_set_lines(buffer_component.buf, 0, -1, false, lines)
end

-- local block = M.new(vim.api.nvim_get_current_buf())
-- block:render()
return M
