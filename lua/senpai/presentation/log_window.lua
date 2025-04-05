local utils = require("senpai.usecase.utils")

---@class senpai.LogWindow
---@field buf integer
local M = {}
M.__index = M

function M.new()
  local self = setmetatable({}, M)
  self.buf = vim.api.nvim_create_buf(false, true)
  if not self.buf then
    error("Failed to create buffer")
  end
  vim.api.nvim_buf_set_name(self.buf, "senpai_develop_log")
  vim.api.nvim_set_option_value(
    "filetype",
    "senpai_develop_log",
    { buf = self.buf }
  )
  vim.keymap.set(
    "n",
    "q",
    ("<CMD>bdelete %d<CR>"):format(self.buf),
    { buffer = self.buf }
  )
  return self
end

function M:mount()
  vim.cmd("split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, self.buf)
end

function M:write(text)
  utils.set_text_at_last(self.buf, text .. "\n")
end

return M
