local Config = require("senpai.config")
local Spinner = require("senpai.presentation.shared.spinner")
local RequestHandler = require("senpai.presentation.shared.request_handler")
local Split = require("nui.split")
local utils = require("senpai.usecase.utils")
local send_text = require("senpai.usecase.send_text")

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
}

---@class senpai.ChatWindow: senpai.ChatWindow.Config
local M = {}
M.__index = M

---@class senpai.ChatWindowNewArgs
---@field provider? provider
---@field provider_config? senpai.Config.providers.Provider
---@field system_prompt? string
---@field thread_id? string

---@nodoc
---@param args senpai.ChatWindowNewArgs
---@return senpai.ChatWindow
function M.new(args)
  args = args or {}
  local self = setmetatable({}, M)
  if args.provider and args.provider_config then
    self.provider = args.provider
    self.provider_config = args.provider_config
  else
    self.provider, self.provider_config = Config.get_provider()
  end

  self.thread_id = args.thread_id
    or vim.fn.getcwd() .. "-" .. os.date("%Y%m%d%H%M%S")

  self.system_prompt = args.system_prompt or ""

  self.hidden = true
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
  self.chat_log:map("n", "q", function()
    self:hide()
  end)
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
  self.chat_input:map("n", "<CR><CR>", function()
    send_text:execute(self)
  end)
  self.chat_input:map("n", "q", function()
    self:hide()
  end)
end

function M:show()
  if not self.chat_log then
    self:create_chat_log()
    self.chat_log:mount()
    utils.set_text_at_last(
      self.chat_log.bufnr,
      string.format(
        [[
---
provider: "%s"
model: "%s"
---
]],
        self.provider,
        self.provider_config.model
      )
    )
  end
  self.chat_log:show()

  if not self.chat_input then
    self:create_chat_input()
    self.chat_input:mount()
  else
    self.chat_input:update_layout({
      relative = "win",
      position = "bottom",
    })
  end
  self.chat_input:show()

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
