---@diagnostic disable: unused-local

---@class Senpai.message.IAssistantHandler
---@field tag_name string
---@field chat senpai.IChatWindow
---@field current_content string
---@field current_tag string|nil
---@field handlers table<string, fun(self:any, chunk:string|nil, line:string|nil)>
local IAssistantHandler = {}
function IAssistantHandler:start_tag() end
function IAssistantHandler:end_tag() end

---@param chunk string
function IAssistantHandler:content_line(chunk) end
