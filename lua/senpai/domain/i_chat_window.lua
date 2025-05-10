---@diagnostic disable: unused-local
local M = {}

---@module "nui.split"
---@module 'plenary.job'

---@class senpai.XML.replace_file
---@field path string
---@field search string[]
---@field replace string[]

---@class senpai.IDiffPopup
---@field bufnr integer
---@field signal { active_tab: NuiSignal<string> }
---@field path string
---@field filetype string
---@field diff_text string
---@field replace_text string
---@field search_text string
---@field body NuiComponent
---@field renderer NuiRenderer
local IDiffPop = {}
function IDiffPop:mount() end
function IDiffPop:show() end
function IDiffPop:hide() end
function IDiffPop:unmount() end
function IDiffPop:focus() end
function IDiffPop:is_focused() end

---@return boolean
function IDiffPop:is_visible()
  return false
end

---@return integer
function IDiffPop:get_width()
  return 1
end

---@param mapping NuiMapping
function IDiffPop:map(mapping) end

---@param tab "diff"|"replace"|"search"
function IDiffPop:change_tab(tab) end

---@param width integer
---@param height integer
function IDiffPop:set_size(width, height) end

---@class senpai.IStickyPopupManager
---@field bufnr integer
---@field winid integer
---@field popups table<integer, senpai.IDiffPopup> # { row: popup }
---@field rows integer[]
---@field group_id integer
local IStickyPopupManager = {}

---@param opts { row: integer, height: integer, filetype: string }
---@return senpai.DiffPopup
---@diagnostic disable-next-line: unused-local
function IStickyPopupManager:add_float_popup(opts)
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
---@field edit_file_results table<string, senpai.tool.EditFile.result> # <[toolCallId]: reuslt>
---@field replace_file_results table<string, senpai.XML.replace_file> # <id: reuslt>
local IChatWindow = {}

---@param winid? number
function IChatWindow:show(winid) end
function IChatWindow:hide() end
function IChatWindow:destroy() end
function IChatWindow:toggle() end
function IChatWindow:toggle_input() end

---@param row integer
---@param path string
---@return senpai.IDiffPopup
function IChatWindow:add_diff_popup(row, path)
  return {}
end

M.input_winbar_text = "Ask Senpai (?: help)"

return M
