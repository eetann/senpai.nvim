--- *senpai* Senpai is super reliable!
---
--- ==============================================================================
--- Table of Contents                                  *senpai-table-of-contents*
---@toc
---@text

local senpai = require("senpai.presentation.api")

senpai.config = {
  word = "Hello!",
}

---@tag senpai-setup
---@toc_entry Setup
---@text
--- No setup argument is required.
---
senpai.setup = function(args)
  senpai.config = vim.tbl_deep_extend("force", senpai.config, args or {})
  -- require("senpai.presentation.highlight").set_highlights()
  -- require("senpai.presentation.autocmd").set_autocmds()
  require("senpai.presentation.command")
end

return senpai
