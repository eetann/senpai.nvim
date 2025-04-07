local M = {}

---@module "nui.split"
---@module 'plenary.job'

---@class senpai.XML.replace_file
---@field path string
---@field search string[]
---@field replace string[]

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
---@field is_sending boolean
---@field is_first_message boolean
---@field job? Job
---@field edit_file_results table<string, senpai.tool.EditFile.result> # <[toolCallId]: reuslt>
---@field replace_file_results table<string, senpai.XML.replace_file> # <id: reuslt>
local IChatWindow = {}

---@param winid? number
---@diagnostic disable-next-line: unused-local
function IChatWindow:show(winid) end
function IChatWindow:hide() end
function IChatWindow:destroy() end
function IChatWindow:toggle() end
function IChatWindow:toggle_input() end

M.input_winbar_text = "Ask Senpai (?: help)"

return M
