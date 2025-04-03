local M = {}

---@doc.type
---@class senpai.Config.chat.keymap
---@field [1]? string|fun(self: senpai.IChatWindow):nil
---@field key? string
---@field mode? string|string[]
---@field desc string

------@doc.type
---@alias senpai.Config.chat.action false|string|senpai.Config.chat.keymap|function

---@class senpai.Config.chat.actions
---@field abort? senpai.Config.chat.action
--[=[@doc
  category = "chat_action"
  name = "abort"
  desc = "Abort the current interaction with the LLM"
  default_key = "`<C-c>`"
--]=]
---@field apply? senpai.Config.chat.action
--[=[@doc
  category = "chat_action"
  name = "apply"
  desc = "Apply the contents of the `Replace File` block to a file"
  default_key = "`a` in log area"
  --]=]
---@field close? senpai.Config.chat.action
--[=[@doc
  category = "chat_action"
  name = "close"
  desc = "close chat"
  default_key = "`q`"
  --]=]
---@field load_thread? senpai.Config.chat.action
--[=[@doc
  category = "chat_action"
  name = "load_thread"
  desc = "load thread. detail -> |senpai-feature-history|"
  default_key = "`gl`"
  --]=]
---@field help? senpai.Config.chat.action
--[=[@doc
  category = "chat_action"
  name = "help"
  desc = "show chat's keymap help"
  default_key = "`?`"
  --]=]
---@field new_thread? senpai.Config.chat.action
--[=[@doc
  category = "chat_action"
  name = "new_thread"
  desc = "replace new thread. detail -> |senpai-api-new_thread|"
  default_key = "`gx`"
  --]=]
---@field regist_url_at_rag? senpai.Config.chat.action
--[=[@doc
  category = "chat_action"
  name = "regist_url_at_rag"
  desc = "Fetch URL and save to RAG"
  default_key = "`gR` in input area"
  --]=]
---@field show_log? senpai.Config.chat.action
--[=[@doc
  category = "chat_action"
  name = "show_log"
  desc = "*For Developers.* show internal API log"
  --]=]
---@field show_mcp_tools? senpai.Config.chat.action
--[=[@doc
  category = "chat_action"
  name = "show_mcp_tools"
  desc = "*For Developers.* show MCP Tools"
  --]=]
---@field show_system_prompt? senpai.Config.chat.action
--[=[@doc
  category = "chat_action"
  name = "show_system_prompt"
  desc = "Show system prompt associated with current chat"
  default_key = "`gs` in log area"
  --]=]
---@field submit? senpai.Config.chat.action
--[=[@doc
  category = "chat_action"
  name = "submit"
  desc = "Send the text in the input area to the LLM"
  default_key = "`<CR>` in input area"
  --]=]
---@field toggle_input? senpai.Config.chat.action
--[=[@doc
  category = "chat_action"
  name = "foo"
  desc = "Toggle display of input area"
  default_key = "`gi`"
  --]=]

---@doc.type
---@alias senpai.Config.chat.keymaps senpai.Config.chat.actions

---@doc.type
---@class senpai.Config.chat.common
---@field keymaps? senpai.Config.chat.keymaps

---@doc.type
---@class senpai.Config.chat.log_area
---@field keymaps? senpai.Config.chat.keymaps

---@doc.type
---@class senpai.Config.chat.input_area
---@field keymaps? senpai.Config.chat.keymaps

---@doc.type
---@class senpai.Config.chat
---@field common? senpai.Config.chat.common
---@field log_area? senpai.Config.chat.log_area
---@field input_area? senpai.Config.chat.input_area
---@field system_prompt? string

---@type senpai.Config.chat
M.default_config = {
  common = {
    keymaps = {
      ["?"] = "help",
      q = "close",
      gx = "new_thread",
      gl = "load_thread",
      gi = "toggle_input",
      ["<C-c>"] = "abort",
    },
  },
  log_area = { keymaps = {
    a = "apply",
    gs = "show_system_prompt",
  } },
  input_area = {
    keymaps = {
      ["<CR>"] = "submit",
      gR = "regist_url_at_rag",
    },
  },
}

return M
