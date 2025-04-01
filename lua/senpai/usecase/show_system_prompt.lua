local Popup = require("nui.popup")

local M = {}

---@param chat senpai.IChatWindow
function M.execute(chat)
  local content = chat.system_prompt
  if not content or content == "" then
    content = "*No system prompt*"
  end

  local popup = Popup({
    relative = "editor",
    position = "50%",
    size = {
      width = "60%",
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
        top = "System prompt",
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
  local keys = { "<esc>", "q", "<C-c>", "<CR>" }
  for _, key in pairs(keys) do
    popup:map("n", key, function()
      popup:unmount()
    end)
  end
end

return M
