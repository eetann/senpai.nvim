local utils = require("senpai.usecase.utils")

local M = {}

---@param chat senpai.IChatWindow
---@param part senpai.data_stream_protocol type = "3"
function M.render_from_response(chat, part)
  local render_text = string.format(
    [[

**Error message received:**
```txt
%s
```
]],
    part.content --[[@as string]]
  )
  utils.set_text_at_last(chat.log_area.bufnr, render_text)
end

return M
