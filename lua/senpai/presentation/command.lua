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

local function get_complete(subcmd_arg_lead, args)
  return vim
    .iter(args)
    :filter(function(arg)
      return arg:find(subcmd_arg_lead) ~= nil
    end)
    :totable()
end

---@type table<string, Senpai.Subcommand>
---@private
local subcmd_tbl = {
  helloDenops = {
    impl = function()
      require("senpai.presentation.api").hello()
    end,
  },
  commitMessage = {
    impl = function(args)
      require("senpai.presentation.api").write_commit_message(args[1])
    end,
    complete = function(subcmd_arg_lead)
      local args = {
        "English",
        "Japanese",
        "Spanish",
        "Chinese",
        "Japanese(ツンデレ風)",
      }
      return get_complete(subcmd_arg_lead, args)
    end,
  },
  summarize = {
    impl = function(args)
      require("senpai.presentation.api").summarize(args[1])
    end,
  },
}

---@param opts table :h lua-guide-commands-create
---@private
local function execute_command(opts)
  local fargs = opts.fargs
  local subcmd_key = fargs[1]

  local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
  local subcmd = subcmd_tbl[subcmd_key]

  if not subcmd then
    vim.notify("Senpai: Unknown command: " .. subcmd_key, vim.log.levels.ERROR)
    return
  end
  subcmd.impl(args, opts)
end

vim.api.nvim_create_user_command("Senpai", execute_command, {
  nargs = "+",
  desc = "Senpai command with sub command completions",
  complete = function(arg_lead, cmdline, _)
    local subcmd_key, subcmd_arg_lead =
      cmdline:match("^['<,'>]*Senpai[!]*%s(%S+)%s(.*)$")
    if
      subcmd_key
      and subcmd_arg_lead
      and subcmd_tbl[subcmd_key]
      and subcmd_tbl[subcmd_key].complete
    then
      return subcmd_tbl[subcmd_key].complete(subcmd_arg_lead)
    end
    if cmdline:match("^['<,'>]*Senpai[!]*%s+%w*$") then
      local subcmd_keys = vim.tbl_keys(subcmd_tbl)
      return vim
        .iter(subcmd_keys)
        :filter(function(key)
          return key:find(arg_lead) ~= nil
        end)
        :totable()
    end
  end,
  bang = false,
})
