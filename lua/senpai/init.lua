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
  type = "`|senpai.Config|`"
  desc = "Setup senpai"
--]=]
---@param opts? senpai.Config see |senpai-config|
senpai.setup = function(opts)
  require("senpai.config").setup(opts)
  require("senpai.presentation.server").start_server()
  -- require("senpai.presentation.highlight").set_highlights()
  require("senpai.command")
end

return senpai
