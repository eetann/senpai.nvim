local M = {}

---@doc.type
---@class senpai.Config.chat.keymap
---@field [1]? string|fun(self: senpai.IChatWindow):nil
---@field key? string
---@field mode? string|string[]
---@field desc string

---@enum (key) senpai.Config.chat.actions
---@diagnostic disable-next-line: unused-local
local actions = {
  --[=[@doc
  category = "chat_action"
  name = "abort"
  desc = "Abort the current interaction with the LLM"
  default_key = "`<C-c>`"
  --]=]
  abort = false,

  --[=[@doc
  category = "chat_action"
  name = "apply"
  desc = "Apply the contents of the `Replace File` block to a file"
  default_key = "`a` in log area"
  --]=]
  --
  apply = false,

  --[=[@doc
  category = "chat_action"
  name = "close"
  desc = "close chat"
  default_key = "`q`"
  --]=]
  --
  close = false,

  --[=[@doc
  category = "chat_action"
  name = "load_thread"
  desc = "load thread. detail -> |senpai-feature-history|"
  default_key = "`gl`"
  --]=]
  --
  load_thread = false,

  --[=[@doc
  category = "chat_action"
  name = "help"
  desc = "show chat's keymap help"
  default_key = "`?`"
  --]=]
  --
  help = false,

  --[=[@doc
  category = "chat_action"
  name = "new_thread"
  desc = "replace new thread. detail -> |senpai-api-new_thread|"
  default_key = "`gx`"
  --]=]
  --
  new_thread = false,

  --[=[@doc
  category = "chat_action"
  name = "open_api_doc"
  desc = "*For Developers.* Open internal API docs. You can call the API immediately!"
  --]=]
  --
  open_api_doc = false,

  --[=[@doc
  category = "chat_action"
  name = "regist_url_at_rag"
  desc = "Fetch URL and save to RAG"
  default_key = "`gR` in input area"
  --]=]
  --
  regist_url_at_rag = false,

  --[=[@doc
  category = "chat_action"
  name = "show_log"
  desc = "*For Developers.* show internal API log"
  --]=]
  --
  show_log = false,

  --[=[@doc
  category = "chat_action"
  name = "show_mcp_tools"
  desc = "*For Developers.* show MCP Tools"
  --]=]
  --
  show_mcp_tools = false,

  --[=[@doc
  category = "chat_action"
  name = "show_replace_content"
  desc = "*For Developers.* show Replace File content."
  --]=]
  --
  show_replace_content = false,

  --[=[@doc
  category = "chat_action"
  name = "show_system_prompt"
  desc = "Show system prompt associated with current chat"
  default_key = "`gs` in log area"
  --]=]
  --
  show_system_prompt = false,

  --[=[@doc
  category = "chat_action"
  name = "submit"
  desc = "Send the text in the input area to the LLM"
  default_key = "`<CR>` in input area"
  --]=]
  --
  submit = false,

  --[=[@doc
  category = "chat_action"
  name = "foo"
  desc = "Toggle display of input area"
  default_key = "`gi`"
  --]=]
  --
  toggle_input = false,
}

---@doc.type
---@alias senpai.Config.chat.action
---|false
---|senpai.Config.chat.actions # detail -> |senpai-feature-chat-keymaps|
---|senpai.Config.chat.keymap

---@doc.type
---@alias senpai.Config.chat.keymaps table<string, senpai.Config.chat.action>

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
