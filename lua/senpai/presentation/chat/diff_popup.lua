local n = require("nui-components")

local FLOAT_WIDTH_MARGIN = 2 + 7 -- border(L/R) + signcolumn

---@class senpai.DiffPopup: senpai.IDiffPopup
local M = {}
M.__index = M

---@return NuiBuffer
local function create_buffer_component()
  local bufnr = vim.api.nvim_create_buf(false, true)
  return n.buffer({
    buf = bufnr,
    flex = 1,
    border_style = "rounded",
  })
end

---@param opts { winid:integer, bufnr:integer, row:integer, height:integer }
---@return senpai.DiffPopup
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
        label = "(gD)Diff",
        global_press_key = "gD",
        is_active = is_tab_active("tab-diff"),
        on_press = function()
          self.signal.active_tab = "tab-diff"
        end,
      }),
      n.gap(1),
      n.button({
        label = "(gR)Replace",
        global_press_key = "gR",
        is_active = is_tab_active("tab-replace"),
        on_press = function()
          self.signal.active_tab = "tab-replace"
        end,
      }),
      n.gap(1),
      n.button({
        label = "(gS)Search",
        global_press_key = "gS",
        is_active = is_tab_active("tab-search"),
        on_press = function()
          self.signal.active_tab = "tab-search"
        end,
      }),
      n.gap({ flex = 2 })
    ),
    n.tab({ id = "tab-diff" }, self.tabs.diff),
    n.tab({ id = "tab-replace" }, self.tabs.replace),
    n.tab({ id = "tab-search" }, self.tabs.search)
  )

  local width = vim.api.nvim_win_get_width(opts.winid) - FLOAT_WIDTH_MARGIN
  if width < 35 then
    width = 35
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
    position = 1,
    width = width,
    height = opts.height + 3, -- border + tabar
    keymap = {
      close = nil,
    },
  })
  self.renderer._private.layout_options.relative.winid = opts.winid

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

function M:mount()
  self.renderer:render(self.body)
end

function M:show()
  self.renderer.layout:show()
end

function M:hide()
  self.renderer.layout:hide()
end

function M:close()
  self.renderer:close()
end

---@param tab_name "diff" | "replace" | "search"
---@param lines string[]
function M:set_buffer_content(tab_name, lines)
  local buffer_component = self.tabs[tab_name]
  vim.api.nvim_buf_set_lines(buffer_component.bufnr, 0, -1, false, lines)
end

function M:is_visible()
  return self.renderer.layout.winid ~= nil
end

function M:get_height()
  return self.renderer:get_size().height
end

function M:focus()
  self.renderer:focus()
end

function M:is_focused()
  for _, component in pairs(self.renderer:get_focusable_components()) do
    if component:is_focused() then
      return true
    end
  end
  return false
end

---@param mapping NuiMapping
function M:map(mapping)
  self.renderer:add_mappings({ mapping })
end

return M
