local ChatWindowManager = require("senpai.presentation.chat.window_manager")
local utils = require("senpai.usecase.utils")

local M = {}

function M.get_visual_selection()
  vim.cmd('noau normal! "vy')
  local text = vim.fn.getreg("v")
  vim.fn.setreg("v", {})
  return text
end

--[=[@doc
  category = "api"
  name = "transfer_visual_to_chat"
  desc = """
```lua
senpai.transfer_visual_to_chat()
```
Transfers the selected range in visual mode to the chat input area.
If the chat buffer is not open, it will be opened.
"""
--]=]
function M.transfer_visual_to_chat()
  local text = M.get_visual_selection()
  if text == "" then
    return
  end
  if not text:match("\n$") then
    text = text .. "\n"
  end
  text = "\n```" .. vim.bo.filetype .. "\n" .. text .. "```"

  local chat = ChatWindowManager.get_current_chat()
  if not chat then
    chat = ChatWindowManager.add({})
    if not chat then
      return
    end
    chat:show()
  elseif chat:is_hidden() then
    chat:show()
  end
  utils.set_text_at_last(chat.input_area.bufnr, text)
end

return M
