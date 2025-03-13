local Split = require("nui.split")
local Popup = require("nui.popup")
local chat_log = Split({
  relative = "editor",
  position = "right",
  size = "40%",
  win_options = {
    colorcolumn = "",
    number = false,
    relativenumber = false,
    signcolumn = "no",
    spell = false,
    statuscolumn = " ",
    wrap = true,
  },
  buf_options = {
    filetype = "senpai_chat_log",
  },
})
chat_log:mount()
local chat_input = Split({
  relative = { type = "win", winid = chat_log.winid },
  position = "bottom",
  win_options = {
    colorcolumn = "",
    number = false,
    relativenumber = false,
    signcolumn = "no",
    spell = false,
    statuscolumn = " ",
    wrap = true,
  },
  buf_options = {
    filetype = "senpai_chat_log",
  },
})
chat_input:mount()

local info = vim.fn.getwininfo(chat_log.winid)[1]
local popup = Popup({
  position = {
    row = info.height,
    col = 1,
  },
  size = {
    width = 10,
    height = 1,
  },
  enter = false,
  focusable = false,
  zindex = 50,
  relative = { type = "win", winid = chat_log.winid },
  border = {
    style = "none",
  },
  buf_options = {
    modifiable = true,
    readonly = false,
  },
  win_options = {
    winblend = 10,
    winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
  },
})
popup:mount()
vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, { "Hello World" })
