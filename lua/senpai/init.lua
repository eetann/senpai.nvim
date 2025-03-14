local senpai = {}

--[=[@doc
  category = "api"
  name = "senpai.setup(config)"
  desc = "Setup senpai"

  [[args]]
  name = "config"
  type = "senpai.Config"
  desc = "Setup senpai"
--]=]
---@param opts? senpai.Config see |senpai-config|
senpai.setup = function(opts)
  require("senpai.config").setup(opts)
  -- require("senpai.presentation.highlight").set_highlights()
  require("senpai.presentation.autocmd").set_autocmds()
  require("senpai.command")
end

return senpai
