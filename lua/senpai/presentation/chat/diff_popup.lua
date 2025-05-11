local n = require("nui-components")
local Gap = require("nui-components.gap")
local Columns = require("nui-components.columns")
local Button = require("senpai.presentation.shared.button")
local utils = require("senpai.usecase.utils")

local FLOAT_WIDTH_MARGIN = 7 -- signcolumn

---@class senpai.DiffPopup: senpai.IDiffPopup
local M = {}
M.__index = M

---@param opts { winid:integer, bufnr:integer, row:integer, path:string }
---@return senpai.DiffPopup
function M.new(opts)
  local self = setmetatable({}, M)
  self.row = opts.row
  self.winid = opts.winid
  self.bufnr = opts.bufnr
  self.path = opts.path
  self.filetype = utils.get_filetype(opts.path)
  self.signal = n.create_signal({
    active_tab = "no-tab",
  })
  self.diff_text = ""
  self.replace_text = ""
  self.search_text = ""
  self:setup()

  return self
end

function M:setup()
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
          require("senpai.presentation.change_replace_tab").change_replace_tab(
            "diff",
            self.row
          )
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
          require("senpai.presentation.change_replace_tab").change_replace_tab(
            "replace",
            self.row
          )
        end,
      }),
      Gap({ size = 1 }, { zindex = 49 }),
      Button({
        label = "Search",
        global_press_key = "S",
        is_active = is_tab_active("tab-search"),
        on_press = function()
          self.signal.active_tab = "tab-search"
          require("senpai.presentation.change_replace_tab").change_replace_tab(
            "search",
            self.row
          )
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

  local width = M.adjust_width(vim.api.nvim_win_get_width(self.winid))
  self.renderer = n.create_renderer({
    bufnr = self.bufnr,
    relative = {
      type = "buf",
      position = {
        row = self.row - 1,
        col = 0,
      },
    },
    position = 1,
    width = width,
    height = 1,
    keymap = {
      close = nil,
      focus_next = nil,
      focus_prev = nil,
    },
  })
  self.renderer._private.layout_options.relative.winid = self.winid

  self.renderer:add_mappings({
    {
      mode = "n",
      key = "q",
      handler = function()
        vim.api.nvim_win_close(self.winid, false)
      end,
    },
  })
  self:setup_keymaps()
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
      require("senpai.presentation.change_replace_tab").change_replace_tab(
        v.tab,
        self.row
      )
    end, { buffer = self.bufnr })
  end
end

function M.adjust_width(width)
  width = width - FLOAT_WIDTH_MARGIN
  if width < 35 then
    return 35
  end
  return width
end

function M:mount()
  self.renderer:render(self.body)
end

function M:unmount()
  self.renderer:close()
end

function M:renew(winid)
  self.winid = winid
  self:setup()
end

function M:show()
  if not self.renderer.layout then
    self:mount()
  end
  self.renderer.layout:show()
end

function M:hide()
  if self.renderer.layout then
    self.renderer.layout:hide()
  end
end

function M:is_visible()
  return self.renderer.layout and self.renderer.layout.winid ~= nil
end

function M:focus(to_last)
  if to_last then
    local focusable_components = self.renderer:get_focusable_components()
    local prev = focusable_components[#focusable_components]
    vim.api.nvim_set_current_win(prev.winid)
    return
  end
  local first_focusable_component = require("nui-components.utils.fn").ifind(
    self.renderer._private.flatten_tree,
    function(component)
      return component:is_focusable()
    end
  )
  if first_focusable_component then
    first_focusable_component:focus()
  end
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

function M:change_tab(tab)
  if tab == "diff" then
    self.signal.active_tab = "tab-diff"
  elseif tab == "replace" then
    self.signal.active_tab = "tab-replace"
  elseif tab == "search" then
    self.signal.active_tab = "tab-search"
  end
end

function M:set_size(width, height)
  self.renderer:set_size({
    width = width,
    height = height,
  })
end

function M:get_width()
  return self.renderer:get_size().width
end

-- local block = M.new({
--   winid = vim.api.nvim_get_current_win(),
--   bufnr = vim.api.nvim_get_current_buf(),
--   row = 2,
-- })
-- block:mount()
return M
