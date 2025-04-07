local Popup = require("nui.popup")

local M = {}

---@param title string
---@param content string
function M.execute(title, content)
  local keys = { "<ESC>", "q", "<C-c>", "<CR>" }
  local popup = Popup({
    relative = "editor",
    position = "50%",
    size = {
      width = "40%",
      height = "80%",
    },
    border = {
      padding = {
        top = 1,
        bottom = 1,
        left = 1,
        right = 1,
      },
      style = "rounded",
      text = {
        top = title .. " (" .. table.concat(keys, "/") .. "...close)",
        top_align = "center",
      },
    },
    buf_options = {
      filetype = "markdown",
    },
    enter = true,
  })
  popup:mount()
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, vim.split(content, "\n"))
  vim.bo[popup.bufnr].modifiable = false
  vim.bo[popup.bufnr].readonly = true
  for _, key in pairs(keys) do
    popup:map("n", key, function()
      popup:unmount()
    end)
  end
end

return M
