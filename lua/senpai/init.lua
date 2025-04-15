local senpai = {}

--[=[@doc
  category = "api"
  name = "setup"
  desc = """
```lua
senpai.setup({...})
```
Setup senpai
"""

  [[args]]
  name = "config"
  type = "|`senpai.Config`|"
  desc = "Setup senpai"
--]=]
---@param opts? senpai.Config see |senpai-config|
senpai.setup = function(opts)
  vim.treesitter.language.register("markdown", "senpai_chat_log")
  vim.treesitter.language.register("markdown", "senpai_chat_input")
  require("senpai.config").setup(opts)
  require("senpai.presentation.client").start_server()
  -- require("senpai.presentation.highlight").set_highlights()
  require("senpai.command")
  require("senpai.presentation.completion.init")
end

return senpai
