local n = require("nui-components")

---@module "nui.layout"
---@module "nui-components.renderer"

---@alias senpai.block_type "replace_in_file"|"execute_command"|"ask_followup_question"|"write_to_file"

---@alias senpai.action_block { label: string, action_type: string, approve: boolean }

---@class senpai.IBlock
---@field block_type senpai.block_type
---@field row integer
---@field winid integer
---@field bufnr integer
---@field body NuiComponent
---@field renderer NuiRenderer
---@field get_action_buttons? fun():(senpai.action_block[]|string)
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
  if not self:has_ui() then
    return
  end

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
  if not self:has_ui() then
    return
  end
  self.renderer:render(self.body)
end

function M:unmount()
  if not self:has_ui() then
    return
  end
  self.renderer:close()
end

---@param winid integer
function M:renew(winid)
  self.winid = winid
  self:setup()
end

function M:show()
  if not self:has_ui() then
    return
  end
  if not self.renderer.layout then
    self:mount()
  end
  self.renderer.layout:show()
end

function M:hide()
  if not self:has_ui() then
    return
  end
  if self.renderer.layout then
    self.renderer.layout:hide()
  end
end

---@return boolean
function M:is_visible()
  if not self:has_ui() then
    return false
  end
  return self.renderer.layout and self.renderer.layout.winid ~= nil
end

---Check if this block has UI components (body/renderer)
---@return boolean
function M:has_ui()
  -- Default implementation returns true for backward compatibility
  -- Subclasses can override this to return false for UI-less blocks
  return true
end

---@param action_type string
---@param user_input? string
---@return { success: boolean, message: string }
function M:handle_action(action_type, user_input)
  return { success = false, message = "Not implemented" }
end

---@param to_last boolean|nil
function M:focus(to_last)
  if not self:has_ui() then
    return
  end
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
  if not self:has_ui() then
    return false
  end
  for _, component in pairs(self.renderer:get_focusable_components()) do
    if component:is_focused() then
      return true
    end
  end
  return false
end

---@param mapping NuiMapping
function M:map(mapping)
  if not self:has_ui() then
    return
  end
  self.renderer:add_mappings({ mapping })
end

---@param width integer
---@param height integer
function M:set_size(width, height)
  if not self:has_ui() then
    return
  end
  self.renderer:set_size({
    width = width,
    height = height,
  })
end

---@return integer
function M:get_width()
  if not self:has_ui() then
    return 0
  end
  return self.renderer:get_size().width
end

-- types ---

---@class senpai.IReplaceInFileBlock: senpai.IBlock
---@field block_type "replace_in_file"
---@field signal { active_tab: NuiSignal<string> }
---@field path string
---@field filetype string
---@field diffs {search:string, replace:string, diff:string}[]
---@field ai_bufnr integer|nil
---@field origin_bufnr integer|nil
---@field change_tab fun(self, tab: "diff"|"replace"|"search"):nil
---@field tool_result fun(self, result: senpai.chat.message.result.replace_in_file):nil

---@class senpai.IAskFollowupQuestionBlock: senpai.IBlock
---@field block_type "ask_followup_question"
---@field question string
---@field followUp string[]
---@field tool_result fun(self, result: senpai.chat.message.result.ask_followup_question):nil

return M
