local M = {}

---@doc.type
---@class senpai.Config.chat.keymap
---@field [1]? string|fun(self: senpai.IChatWindow):nil
---@field key? string
---@field mode? string|string[]
---@field desc string

---@doc.type
---@alias senpai.Config.chat.keymaps table<string, false|string|senpai.Config.chat.keymap>

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
