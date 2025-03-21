local CommandResiter = require("senpai.presentation.command_register")

---@class Senpai.Subcommand
---@field impl fun(args:string[], opts: table) The comand implementation
---@field complete? fun(subcmd_arg_lead: string): string[] (optional) Command completions callback, taking the lead of the subcommand's arguments
---@private

---@type table<string, Senpai.Subcommand>
---@private
local subcmd_tbl = {
  --[=[@doc
  category = "command"
  name = "commitMessage"
  desc = "detail -> |senpai-api-write_commit_message|"

  [[args]]
  name = "language"
  desc = "language"
  --]=]
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
  --[=[@doc
  category = "command"
  name = "toggleChat"
  desc = "detail -> |senpai-feature-chat|"
  --]=]
  toggleChat = {
    impl = function()
      require("senpai.api").toggle_chat()
    end,
  },
  --[=[@doc
  category = "command"
  name = "loadThread"
  desc = "detail -> |senpai-feature-history|"
  --]=]
  loadThread = {
    impl = function()
      require("senpai.api").load_thread()
    end,
  },
  _hello = {
    impl = function()
      require("senpai.api").hello()
    end,
  },
  _helloStream = {
    impl = function()
      require("senpai.api").hello_stream()
    end,
  },
}

CommandResiter.regist(subcmd_tbl)
