local content_popup = require("senpai.usecase.popup.content_popup")
local utils = require("senpai.usecase.utils")

local M = {}

---@param chat senpai.IChatWindow
function M.execute(chat)
  local id = utils.get_replace_file_id()
  if id == "" then
    return
  end
  local result = chat.replace_file_results[id]
  local filetype = utils.get_filetype(result.path)
  local content = string.format(
    [[
filepath: %s

## search
```%s
%s
```

## replace
```%s
%s
```
  ]],
    result.path,
    filetype,
    table.concat(result.search, "\n"),
    filetype,
    table.concat(result.replace, "\n")
  )
  content_popup.execute("System prompt", content)
end

return M
