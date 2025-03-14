local M = {}

---get complete for cmdline
---@param subcmd_arg_lead string typing string
---@param args string[] candidate list
---@return table
function M.get_complete(subcmd_arg_lead, args)
  return vim
    .iter(args)
    :filter(function(arg)
      return arg:find(subcmd_arg_lead) ~= nil
    end)
    :totable()
end

---@param opts table :h lua-guide-commands-create
function M.execute_command(subcmd_tbl, opts)
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

function M.regist(subcmd_tbl)
  vim.api.nvim_create_user_command("Senpai", function(opts)
    M.execute_command(subcmd_tbl, opts)
  end, {
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
end
return M
