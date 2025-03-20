-- system

---@class senpai.chat.message.system
---@field role "system"
---@field content string

--- user

---@class senpai.chat.message.part.text
---@field type "text"
---@field text string

---@alias senpai.chat.data.content string|table string,Uint8Array,ArrayBuffer,Buffer

---@class senpai.chat.message.part.image
---@field type "image"
---@field image senpai.chat.data.content|string
---@field mimeType? string

---@class senpai.chat.message.part.file
---@field type "file"
---@field data senpai.chat.data.content|string
---@field filename? string
---@field mimeType string

---@alias senpai.chat.message.user.part
---| senpai.chat.message.part.text
---| senpai.chat.message.part.image
---| senpai.chat.message.part.file

---@alias senpai.chat.message.user.content string|senpai.chat.message.user.part[]

---@class senpai.chat.message.user
---@field role "user"
---@field content senpai.chat.message.user.content

-- assistant

---@class senpai.chat.message.part.reasoning
---@field type "reasoning"
---@field text string
---@field signature? string

---@class senpai.chat.message.part.tool_call
---@field type "tool-call"
---@field toolCallId string
---@field toolName string
---@field args any JSON-serializable object

---@class senpai.chat.message.part.redacted_reasoning
---@field type "redacted-reasoning"
---@field data string

---@alias senpai.chat.message.assistant.part
---| senpai.chat.message.part.text
---| senpai.chat.message.part.reasoning
---| senpai.chat.message.part.redacted_reasoning
---| senpai.chat.message.part.tool_call

---@alias senpai.chat.message.assistant.content
---| string
---| senpai.chat.message.assistant.part[]

---@class senpai.chat.message.assistant
---@field role "assistant"
---@field content senpai.chat.message.assistant.content

-- tool

---@class senpai.chat.tool_result.text
---@field type "text"
---@field text string

---@class senpai.chat.tool_result.image
---@field type "image"
---@field data string
---@field mimeType? string

---@alias senpai.chat.tool_result.content (senpai.chat.tool_result.text|senpai.chat.tool_result.image)[] # Array of tool result content items

---@class senpai.chat.message.part.tool_result
---@field type "tool-result"
---@field toolCallId string
---@field toolName string
---@field result any
---@field experimental_content? senpai.chat.tool_result.content
---@field isError? boolean

---@alias senpai.chat.message.tool.content senpai.chat.message.part.tool_result[]

---@class senpai.chat.message.tool
---@field role "tool"
---@field content senpai.chat.message.tool.content

---@alias senpai.chat.message
---| senpai.chat.message.system
---| senpai.chat.message.user
---| senpai.chat.message.assistant
---| senpai.chat.message.tool
