local M = {}

---@class senpai.Config.chat.keymap: vim.api.keyset.keymap
---@field [1]? string|fun(self: senpai.ChatWindow.Config):nil
---@field key? string
---@field mode? string|string[]
---@field desc string

---@alias senpai.Config.chat.keymaps table<string, false|string|senpai.Config.chat.keymap>

---@class senpai.Config.chat.common
---@field keymaps? senpai.Config.chat.keymaps

---@class senpai.Config.chat.log_area
---@field keymaps? senpai.Config.chat.keymaps

---@class senpai.Config.chat.input_area
---@field keymaps? senpai.Config.chat.keymaps

---@class senpai.Config.chat
---@field common? senpai.Config.chat.common
---@field log_area? senpai.Config.chat.log_area
---@field input_area? senpai.Config.chat.input_area

---@type senpai.Config.chat
M.default_config = {
  common = {
    keymaps = {
      ["?"] = "help",
      q = "close",
      gx = "replace_new_chat",
      gl = "load_thread",
    },
  },
  log_area = {},
  input_area = {
    keymaps = {
      ["<CR>"] = "submit",
    },
  },
}

return M
