local Popup = require("nui.popup")

---@class senpai.YesnoPopup
---@field content string[]
---@field popup NuiPopup
local M = {}
M.__index = M

---@param content string[]
---@return senpai.YesnoPopup
function M.new(content)
  local self = setmetatable({}, M)
  self.content = content
  table.insert(self.content, "[y/N]")

  self.popup = Popup({
    relative = "editor",
    position = "50%",
    size = {
      width = 70,
      height = 3,
    },
    border = {
      padding = {
        top = 1,
        bottom = 1,
        left = 1,
        right = 1,
      },
      style = "rounded",
    },
    enter = true,
  })
  return self
end

---@param callbacks {yes:fun(), no:fun(), cancel:fun()}
function M:execute(callbacks)
  self.popup:mount()

  vim.api.nvim_buf_set_lines(self.popup.bufnr, 0, 1, false, self.content)
  vim.bo[self.popup.bufnr].modifiable = false
  vim.bo[self.popup.bufnr].readonly = true

  self.popup:map("n", "<esc>", function()
    self.popup:unmount()
    callbacks.cancel()
  end)
  self.popup:map("n", "q", function()
    self.popup:unmount()
    callbacks.cancel()
  end)
  self.popup:map("n", "<C-c>", function()
    self.popup:unmount()
    callbacks.cancel()
  end)
  self.popup:map("n", "n", function()
    self.popup:unmount()
    callbacks.no()
  end)
  self.popup:map("n", "N", function()
    self.popup:unmount()
    callbacks.no()
  end)
  self.popup:map("n", "<CR>", function()
    self.popup:unmount()
    callbacks.no()
  end)
  self.popup:map("n", "y", function()
    self.popup:unmount()
    callbacks.yes()
  end)
  self.popup:map("n", "Y", function()
    self.popup:unmount()
    callbacks.yes()
  end)
end

return M
