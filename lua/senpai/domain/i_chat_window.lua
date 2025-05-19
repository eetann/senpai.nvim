---@diagnostic disable: unused-local
local M = {}

---@module "nui.split"
---@module 'plenary.job'

---@class senpai.XML.replace_file
---@field path string
---@field search string[]
---@field replace string[]

---@class senpai.IStickyPopupManager
---@field bufnr integer
---@field winid integer
---@field popups table<integer, senpai.IBlock> # { row: popup }
---@field rows integer[]
---@field group_id integer
---@field add_diff_block fun(self, row: integer, path: string): senpai.IDiffBlock
---@field add_terminal_block fun(self, row: integer): senpai.ITerminalBlock
---@field find_next_popup_row fun(self, block_type: senpai.block_type):integer|nil
---@field find_prev_popup_row fun(self, block_type: senpai.block_type):integer|nil
---@field update_float_position fun(self):nil

---@class senpai.ChatWindowNewArgs
---@field provider? senpai.Config.provider.name|senpai.Config.provider
---@field system_prompt? string
---@field thread_id? string

---@class senpai.IChatWindow
---@field provider senpai.Config.provider
---@field system_prompt string
---@field thread_id string
---@field log_area NuiSplit|nil
---@field input_area NuiSplit|nil
---@field keymaps senpai.chat.Keymaps
---@field sticky_popup_manager senpai.IStickyPopupManager|nil
---@field is_sending boolean
---@field is_first_message boolean
---@field job? Job
local IChatWindow = {}

---@param winid? number
function IChatWindow:show(winid) end
function IChatWindow:hide() end
function IChatWindow:destroy() end
function IChatWindow:toggle() end
function IChatWindow:toggle_input() end

---@param row integer
---@param path string
---@return senpai.IDiffBlock
function IChatWindow:add_diff_block(row, path)
  return {}
end

---@param row integer
---@return senpai.ITerminalBlock
function IChatWindow:add_terminal_block(row)
  return {}
end

M.input_winbar_text = "Ask Senpai (?: help)"

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

return M
