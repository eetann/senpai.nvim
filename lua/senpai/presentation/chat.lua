---@class senpai.Chat
---@field chat_log snacks.win
---@field chat_input snacks.win
---@field layout snacks.layout
local M = {}
M.__index = M

function M.new()
  local self = setmetatable({}, M)
  self.chat_log = self:create_chat_log()
  self.chat_input = self:create_chat_input()
  self.layout = self:create_layout()
  return self
end

---@return snacks.win.Config|{}
function M:get_win_options()
  return {
    backdrop = {
      bg = "NONE",
      blend = 0,
      transparent = true,
    },
    ---@type snacks.win.Keys[]
    keys = {
      q = function()
        self.layout:close()
      end,
    },
    wo = {
      colorcolumn = "",
      number = false,
      relativenumber = false,
      signcolumn = "no",
      spell = false,
      statuscolumn = " ",
      winhighlight = "Normal:NONE,NormalNC:NONE,WinBar:SnacksWinBar,WinBarNC:SnacksWinBarNC",
      wrap = true,
    },
    ft = "markdown",
  }
end

function M:create_chat_log()
  return require("snacks").win(
    vim.tbl_deep_extend("force", self:get_win_options(), {
      bo = {
        filetype = "senpai_chat_log",
      },
    })
  )
end

function M:create_chat_input()
  return require("snacks").win(
    vim.tbl_deep_extend("force", self:get_win_options(), {
      bo = {
        filetype = "senpai_chat_input",
      },
    })
  )
end

function M:create_layout()
  return require("snacks.layout").new({
    wins = {
      chat_log = self.chat_log,
      input = self.chat_input,
    },
    layout = {
      box = "vertical",
      width = 0.3,
      min_width = 50,
      height = 0.8,
      position = "right",
      {
        win = "chat_log",
        title = "Senpai",
        title_pos = "center",
        border = "top",
      },
      {
        win = "input",
        title = "input",
        title_pos = "center",
        border = "top",
        height = 0.3,
      },
    },
  })
end

function M:show()
  self.layout:show()
end

function M:hide()
  self.layout:hide()
end

function M:close()
  self.layout:close()
end

function M:toggle_input()
  self.layout:toggle("chat_input")
end

function M:get_log_buf()
  return self.chat_log.buf
end

function M:get_input_buf()
  return self.chat_input.buf
end

return M
