local Spinner = require("senpai.presentation.shared.spinner")

local M = {}

function M.set_autocmds()
  local init_spinner = Spinner.new("Senpai initialize")

  vim.api.nvim_create_autocmd("User", {
    pattern = "SenpaiInitStart",
    callback = function()
      init_spinner:start()

      vim.defer_fn(function()
        if init_spinner.is_active then
          init_spinner:stop(true)
        end
      end, 30 * 1000)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "SenpaiInitEnd",
    callback = function()
      init_spinner:stop()
    end,
  })

  vim.api.nvim_exec_autocmds("User", { pattern = "SenpaiInitStart" })
end

return M
