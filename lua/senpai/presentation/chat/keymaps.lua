local Menu = require("nui.menu")

local M = {}

function M.execute()
  local menu = Menu({
    position = "50%",
    size = {
      width = 25,
    },
    border = {
      style = "single",
      padding = { 1, 2 },
      text = {
        top = "[senapi] help",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  }, {
    lines = M.create_items(),
    on_submit = function(item)
      print("SUBMITTED", vim.inspect(item))
    end,
  })
  menu:mount()
end

function M.create_items()
  local items = {
    Menu.item("q", { key = "q", level = "TRACE" }),
    Menu.item("input: <CR><CR>", { key = "<CR><CR>", level = "DEBUG" }),
  }
  return items
end

return M
