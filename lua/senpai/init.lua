--- *senpai* Senpai is super reliable!
---
--- ==============================================================================
--- Table of Contents                                  *senpai-table-of-contents*
---@toc
---@text

local senpai = {}

---@tag senpai-setup
---@toc_entry Setup

---@param opts? senpai.Config see |senpai-config|
senpai.setup = function(opts)
  require("senpai.config").setup(opts)
  -- require("senpai.presentation.highlight").set_highlights()
  -- require("senpai.presentation.autocmd").set_autocmds()
  require("senpai.command")
end

return senpai
