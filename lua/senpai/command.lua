local CommandResiter = require("senpai.presentation.command_register")
---@tag senpai-commands
---@toc_entry Commands
---@text
--- Commands ~
--- `:Senpai {subcommand}`
---
--- `:Senpai commitMessage (language)`
---   detail -> |senpai-write-commit-message|

---@class Senpai.Subcommand
---@field impl fun(args:string[], opts: table) The comand implementation
---@field complete? fun(subcmd_arg_lead: string): string[] (optional) Command completions callback, taking the lead of the subcommand's arguments
---@private

---@type table<string, Senpai.Subcommand>
---@private
local subcmd_tbl = {
  helloDenops = {
    impl = function()
      require("senpai.api").hello()
    end,
  },
  commitMessage = {
    impl = function(args)
      require("senpai.api").write_commit_message(args[1])
    end,
    complete = function(subcmd_arg_lead)
      local args = {
        "English",
        "Japanese",
        "Spanish",
        "Chinese",
        "Japanese(ツンデレ風)",
      }
      return CommandResiter.get_complete(subcmd_arg_lead, args)
    end,
  },
  summarizeExample = {
    impl = function()
      require("senpai.api").summarize([[
      Take care of the shopping.
      Two apples and three oranges.
      Oh, and a banana, please.]])
    end,
  },
}

CommandResiter.regist(subcmd_tbl)
