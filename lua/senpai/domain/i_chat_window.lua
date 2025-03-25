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
---@field chat_log NuiSplit|nil
---@field chat_input NuiSplit|nil
---@field hidden boolean
---@field keymaps senpai.chat.Keymaps
---@field is_sending boolean
---@field job? Job
---@field edit_file_results table<string, senpai.tool.EditFile.result> # <[toolCallId]: reuslt>
---@field replace_file_results table<string, senpai.XML.replace_file> # <id: reuslt>
local IChatWindow = {}

---@param winid? number
---@diagnostic disable-next-line: unused-local
function IChatWindow:show(winid) end
function IChatWindow:hide() end
function IChatWindow:destory() end
function IChatWindow:toggle() end
