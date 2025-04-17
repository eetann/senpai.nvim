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
    impl = function(args)
      require("senpai.api").load_thread(args[1])
    end,
  },
  --[=[@doc
  category = "command"
  name = "deleteRagSource"
  desc = "detail -> |senpai-feature-rag|"
  --]=]
  deleteRagSource = {
    impl = function(args)
      require("senpai.api").delete_rag_source(args[1])
    end,
  },
  --[=[@doc
  category = "command"
  name = "newThread"
  desc = "detail -> |senpai-api-new_thread|"
  --]=]
  newThread = {
    impl = function()
      require("senpai.api").new_thread()
    end,
  },
  --[=[@doc
  category = "command"
  name = "promptLauncher"
  desc = "detail -> |senpai-api-prompt_launcher|"
  --]=]
  promptLauncher = {
    impl = function()
      require("senpai.api").prompt_launcher()
    end,
  },
  --[=[@doc
  category = "command"
  name = "transferToChat"
  desc = "detail -> |senpai-api-transfer_visual_to_chat|"
  --]=]
  transferToChat = {
    impl = function()
      require("senpai.api").transfer_visual_to_chat()
    end,
  },
  --[=[@doc
  category = "command"
  name = "reloadRules"
  desc = "detail -> |senpai-api-reload_rules|"
  --]=]
  reloadRules = {
    impl = function()
      require("senpai.api").reload_rules()
    end,
  },
  --[=[@doc
  category = "command"
  name = "_hello"
  desc = """
For developers.
To check communication with internal servers.
"""
  --]=]
  _hello = {
    impl = function()
      require("senpai.api").hello()
    end,
  },
  --[=[@doc
  category = "command"
  name = "_helloStream"
  desc = """
For developers.
To check that streams are received correctly from the internal server.
"""
  --]=]
  _helloStream = {
    impl = function()
      require("senpai.api").hello_stream()
    end,
  },
}

CommandResiter.regist(subcmd_tbl)
