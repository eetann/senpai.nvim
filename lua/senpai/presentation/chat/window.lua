local Config = require("senpai.config")
local Split = require("nui.split")
local utils = require("senpai.usecase.utils")
local set_messages = require("senpai.usecase.set_messages")
local Keymaps = require("senpai.presentation.chat.keymaps")

vim.treesitter.language.register("markdown", "senpai_chat_log")
vim.treesitter.language.register("markdown", "senpai_chat_input")

local function create_winbar_text(text)
  return "%#Nomal#%=" .. text .. "%="
end

local win_options = {
  colorcolumn = "",
  number = false,
  relativenumber = false,
  signcolumn = "yes",
  spell = false,
  statuscolumn = "",
  wrap = true,
  fillchars = "eob: ,lastline:…",
  -- listchars = "eol: ",
}

---@class senpai.ChatWindow: senpai.IChatWindow
local M = {}
M.__index = M

-- TODO: nuiのlayoutへ置き換える

---@param args senpai.ChatWindowNewArgs
---@return senpai.ChatWindow|nil
function M.new(args)
  args = args or {}
  local self = setmetatable({}, M)
  local provider = Config.get_provider(args.provider)
  if not provider then
    return
  end
  self.provider = provider

  self.thread_id = args.thread_id
    or vim.fn.getcwd() .. "-" .. os.date("%Y%m%d%H%M%S")

  self.system_prompt = args.system_prompt or ""

  self.hidden = true
  self.is_sending = false
  return self
end

--- @param keymaps table<string, senpai.Config.chat.keymap>
function M:create_chat_log(keymaps)
  self.chat_log = Split({
    relative = "editor",
    position = "right",
    win_options = vim.tbl_deep_extend("force", win_options, {
      winbar = create_winbar_text("Conversations with Senpai"),
    }),
    buf_options = {
      filetype = "senpai_chat_log",
    },
  })
  for key, value in pairs(keymaps) do
    if type(value.mode) == "string" then
      self.chat_log:map(value.mode--[[@as string]], key, value[1])
    else
      for _, mode in
        pairs(value.mode--[=[@as string[]]=])
      do
        self.chat_log:map(mode, key, value[1])
      end
    end
  end
end

---@param keymaps table<string, senpai.Config.chat.keymap>
function M:create_chat_input(keymaps)
  self.chat_input = Split({
    relative = "win",
    position = "bottom",
    size = "40%",
    win_options = vim.tbl_deep_extend("force", win_options, {
      winbar = create_winbar_text("Ask Senpai"),
    }),
    buf_options = {
      filetype = "senpai_chat_input",
    },
  })
  for key, value in pairs(keymaps) do
    if type(value.mode) == "string" then
      self.chat_input:map(value.mode--[[@as string]], key, value[1])
    else
      for _, mode in
        pairs(value.mode--[=[@as string[]]=])
      do
        self.chat_input:map(mode, key, value[1])
      end
    end
  end
end

function M:show(winid)
  local resolved_keymaps
  if not self.chat_log then
    resolved_keymaps = Keymaps.new(self)
    self:create_chat_log(resolved_keymaps.log_area)
    if winid then
      self.chat_log.winid = winid
      vim.api.nvim_win_set_buf(self.chat_log.winid, self.chat_log.bufnr)
      ---@diagnostic disable-next-line: invisible
      for name, value in pairs(self.chat_log._.win_options) do
        vim.api.nvim_set_option_value(
          name,
          value,
          { scope = "local", win = self.chat_log.winid }
        )
      end
      vim.api.nvim_set_current_win(self.chat_log.winid)
    end
    self.chat_log:mount()
    utils.set_text_at_last(
      self.chat_log.bufnr,
      string.format(
        [[
---
name: "%s"
model_id: "%s"
thread_id: "%s"
---
]],
        self.provider.name,
        self.provider.model_id,
        self.thread_id
      )
    )
    set_messages.execute(self)
  else
    self.chat_log:show()
  end

  if not self.chat_input then
    if not resolved_keymaps then
      resolved_keymaps = Keymaps.new(self)
    end
    self:create_chat_input(resolved_keymaps.input_area)
    self.chat_input:mount()
  else
    self.chat_input:update_layout({
      relative = "win",
      position = "bottom",
    })
    self.chat_input:show()
  end

  vim.api.nvim_set_current_buf(self.chat_input.bufnr)
  vim.cmd("normal G$")
  self.hidden = false
end

function M:hide()
  self.chat_log:hide()
  self.chat_input:hide()
  self.hidden = true
end

function M:destroy()
  self.hidden = true
  self.chat_log:unmount()
  self.chat_input:unmount()
end

function M:toggle()
  if self.hidden then
    self:show()
  else
    self:hide()
  end
end

return M
