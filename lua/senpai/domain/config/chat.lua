local M = {}

---@doc.type
---@class senpai.Config.chat.keymap
---@field [1]? string|fun(self: senpai.IChatWindow):nil
---@field key? string
---@field mode? string|string[]
---@field desc string

---@enum (key) senpai.Config.chat.actions
---@diagnostic disable-next-line: unused-local
M.actions = {
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
  name = "copy_input_or_codeblock"
  desc = "copy user input or replace file block"
  default_key = "`gy` in log area"
  --]=]
  --
  copy_input_or_codeblock = false,

  --[=[@doc
  category = "chat_action"
  name = "jump_to_previous_block"
  desc = "jump to previous user input or replace file block"
  default_key = "`[[`"
  --]=]
  --
  jump_to_previous_block = false,

  --[=[@doc
  category = "chat_action"
  name = "jump_to_next_block"
  desc = "jump to next user input or replace file block"
  default_key = "`]]`"
  --]=]
  --
  jump_to_next_block = false,

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
  name = "show_internal_log"
  desc = "*For Developers.* show internal API log"
  --]=]
  --
  show_internal_log = false,

  --[=[@doc
  category = "chat_action"
  name = "show_mcp_tools"
  desc = "*For Developers.* show MCP Tools"
  --]=]
  --
  show_mcp_tools = false,

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
---@field width? number|string column number or width percentage string for chat window
---  width = 50 -- 50 column number
---  width = 40% -- 40% chat window width relative to editor

---@doc.type
---@class senpai.Config.chat.log_area
---@field keymaps? senpai.Config.chat.keymaps
---@field replace_show_type? "diff"|"replace"

---@doc.type
---@class senpai.Config.chat.input_area
---@field keymaps? senpai.Config.chat.keymaps
---@field height? number|string row number or height percentage string for input area
---  height = 5 -- 5 row number
---  height = 25% -- 25% input area height relative to chat window
---@field keep_file_attachment? boolean
--- If set to true, files are automatically attached in the next message when attached.

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
      ["[["] = "jump_to_previous_block",
      ["]]"] = "jump_to_next_block",
    },
    width = 80,
  },
  log_area = {
    keymaps = {
      a = "apply",
      gs = "show_system_prompt",
      gy = "copy_input_or_codeblock",
    },
    replace_show_type = "diff",
  },
  input_area = {
    keymaps = {
      ["<CR>"] = "submit",
      gR = "regist_url_at_rag",
    },
    height = "25%",
    keep_file_attachment = true,
  },
}

return M
