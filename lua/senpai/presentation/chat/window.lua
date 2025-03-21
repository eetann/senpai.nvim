local Config = require("senpai.config")
local Split = require("nui.split")
local utils = require("senpai.usecase.utils")
local send_text = require("senpai.usecase.send_text")
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

---@class senpai.ChatWindow: senpai.ChatWindow.Config
---@field keymaps senpai.chat.Keymaps
---@field is_sending boolean
---@field job? Job
local M = {}
M.__index = M

---@class senpai.ChatWindowNewArgs
---@field provider? senpai.Config.provider.name|senpai.Config.provider
---@field system_prompt? string
---@field thread_id? string

-- TODO: nuiのlayoutへ置き換える

---@nodoc
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
  self.keymaps = Keymaps.new(self)
  self.is_sending = false
  return self
end

function M:create_chat_log()
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
  for key, value in pairs(self.keymaps.log_area) do
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

function M:create_chat_input()
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
  for key, value in pairs(self.keymaps.input_area) do
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

---@param winid? number
function M:show(winid)
  if not self.chat_log then
    self:create_chat_log()
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
---
]],
        self.provider.name,
        self.provider.model_id
      )
    )
    set_messages.execute(self)
  else
    self.chat_log:show()
  end

  if not self.chat_input then
    self:create_chat_input()
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
  self.chat_log:unmount()
  self.chat_input:unmount()
  self.hidden = true
end

function M:toggle()
  if self.hidden then
    self:show()
  else
    self:hide()
  end
end

function M:get_log_buf()
  return self.chat_log.bufnr
end

function M:get_input_buf()
  return self.chat_input.bufnr
end

return M
