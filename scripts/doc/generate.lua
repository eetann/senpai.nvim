local MiniDoc = require("mini.doc")
local hooks = vim.deepcopy(MiniDoc.default_hooks)

hooks.write_pre = function(lines)
  -- Remove first two lines with `======` and `------` delimiters to comply
  -- with `:h local-additions` template
  table.remove(lines, 1)
  table.remove(lines, 1)
  return lines
end
hooks.sections["@nodoc"] = function(s)
  s.parent:clear_lines()
end

MiniDoc.generate({
  "lua/senpai/init.lua",
  "lua/senpai/config.lua",
  "lua/senpai/presentation/chat_buffer.lua",
  "lua/senpai/api.lua",
  "lua/senpai/presentation/commit_message.lua",
  "lua/senpai/command.lua",
}, "doc/senpai.txt", { hooks = hooks })
