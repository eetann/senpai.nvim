local n = require("nui-components")

---@module "nui.layout"
---@module "nui-components.renderer"

---@alias senpai.block_type "diff"|"terminal"|nil

---@class senpai.IBlock
---@field block_type senpai.block_type
---@field row integer
---@field winid integer
---@field bufnr integer
---@field body NuiComponent
---@field renderer NuiRenderer
local M = {}
M.__index = M

M.FLOAT_WIDTH_MARGIN = 7 -- signcolumn

---@param winid integer
---@return integer
function M.get_adjust_width(winid)
  local width = vim.api.nvim_win_get_width(winid)
  width = width - M.FLOAT_WIDTH_MARGIN
  if width < 35 then
    return 35
  end
  return width
end

function M:setup_body() end

function M:setup()
  self:setup_body()
  local width = M.get_adjust_width(self.winid)
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

function M:setup_keymaps() end

function M:mount()
  self.renderer:render(self.body)
end

function M:unmount()
  self.renderer:close()
end

---@param winid integer
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

---@return boolean
function M:is_visible()
  return self.renderer.layout and self.renderer.layout.winid ~= nil
end

---@param to_last boolean|nil
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

---@param width integer
---@param height integer
function M:set_size(width, height)
  self.renderer:set_size({
    width = width,
    height = height,
  })
end

---@return integer
function M:get_width()
  return self.renderer:get_size().width
end

-- types ---

---@class senpai.IDiffBlock: senpai.IBlock
---@field block_type "diff"
---@field signal { active_tab: NuiSignal<string> }
---@field path string
---@field filetype string
---@field diff_text string
---@field replace_text string
---@field search_text string
---@field change_tab fun(self, tab: "diff"|"replace"|"search"):nil

---@class senpai.ITerminalBlock: senpai.IBlock
---@field block_type "terminal"
---@field command string
---@field result string
---@field term_bufnr integer|nil
---@field job_id integer
---@field term_id integer

return M
