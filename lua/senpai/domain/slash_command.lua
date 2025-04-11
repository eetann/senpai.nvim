local M = {}

---@class senpai.SlashCommand
---@field description string
---@field callback (string|fun():nil)

---@type table<string, senpai.SlashCommand>
M.slash_commands = {
  file = {
    description = "Attach a file to a message",
    callback = "attach_file",
  },
  help = {
    description = "Help for slash command",
    callback = "help_for_slash_command",
  },
}

return M
