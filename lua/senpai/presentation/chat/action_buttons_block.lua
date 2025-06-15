local IBlock = require("senpai.domain.i_block")
local n = require("nui-components")
local Columns = require("nui-components.columns")
local utils = require("senpai.usecase.utils")

---@class senpai.ActionButtonsBlock: senpai.IBlock
---@field block_type "action_buttons"
---@field buttons table[]
---@field target_block senpai.IBlock The block that these action buttons are for
---@field chat_window any The chat window instance
local M = {}
M.__index = M
setmetatable(M, { __index = IBlock })

---@param opts { winid:integer, bufnr:integer, row:integer|nil, buttons:table[], target_block:any, chat_window:any }
---@return senpai.ActionButtonsBlock
function M.new(opts)
  local self = setmetatable({}, M)
  self.block_type = "action_buttons"
  self.buttons = opts.buttons
  self.target_block = opts.target_block
  self.chat_window = opts.chat_window

  -- Position at the end of buffer if row not specified
  local row = opts.row or vim.api.nvim_buf_line_count(opts.bufnr)
  self.row = row
  self.winid = opts.winid
  self.bufnr = opts.bufnr

  self:setup()
  utils.replace_text_at_last(self.bufnr, "\n\n")
  self:mount()

  return self
end

function M:setup_body()
  -- Build button components
  local button_components = {}
  local button_count = #self.buttons
  for i, button_def in ipairs(self.buttons) do
    local mappings = nil
    if i == 1 then
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
      end
    elseif i == button_count then
      mappings = function()
        return {
          {
            mode = "n",
            key = "<Tab>",
            handler = function()
              utils.safe_set_current_win(self.chat_window.input_area.winid)
            end,
          },
        }
      end
    end
    table.insert(
      button_components,
      n.button({
        label = button_def.label,
        flex = 1,
        align = "center",
        on_press = function()
          -- Execute the action through the chat window
          self.chat_window:_execute_action(button_def, self.target_block)
          self:hide()
          self.target_block = nil
        end,
        mappings = mappings,
      })
    )
  end

  self.body = Columns({
    flex = 1,
    children = button_components,
  })
end

function M:has_ui()
  if self.target_block then
    return true
  end
  return false
end

return M

