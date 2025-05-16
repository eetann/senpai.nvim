---@diagnostic disable: unused-local
local M = {}

---@module "nui.split"
---@module 'plenary.job'

---@class senpai.XML.replace_file
---@field path string
---@field search string[]
---@field replace string[]

---@class senpai.IBlock
---@field row integer
---@field winid integer
---@field bufnr integer
---@field body NuiComponent
---@field renderer NuiRenderer
local IBlock = {}
function IBlock:mount() end
function IBlock:show() end
function IBlock:hide() end
function IBlock:unmount() end
function IBlock:is_focused() end

---@param to_last boolean|nil
function IBlock:focus(to_last) end

---@param winid integer
function IBlock:renew(winid) end

---@return boolean
function IBlock:is_visible()
  return false
end

---@return integer
function IBlock:get_width()
  return 1
end

---@param mapping NuiMapping
function IBlock:map(mapping) end

---@param width integer
---@param height integer
function IBlock:set_size(width, height) end

---@class senpai.IDiffBlock: senpai.IBlock
---@field signal { active_tab: NuiSignal<string> }
---@field path string
---@field filetype string
---@field diff_text string
---@field replace_text string
---@field search_text string
local IDiffBlock = {}
---@param tab "diff"|"replace"|"search"
function IDiffBlock:change_tab(tab) end

---@class senpai.IStickyPopupManager
---@field bufnr integer
---@field winid integer
---@field popups table<integer, senpai.IBlock> # { row: popup }
---@field rows integer[]
---@field group_id integer
local IStickyPopupManager = {}

---@param opts { row: integer, height: integer, filetype: string }
---@return senpai.DiffBlock
---@diagnostic disable-next-line: unused-local
function IStickyPopupManager:add_diff_block(opts)
  return {}
end

---@return integer|nil
function IStickyPopupManager:find_next_popup_row() end
---@return integer|nil
function IStickyPopupManager:find_prev_popup_row() end

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

M.input_winbar_text = "Ask Senpai (?: help)"

return M
