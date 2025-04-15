-- https://cmp.saghen.dev/development/source-boilerplate.html
local SlashCommand = require("senpai.domain.slash_command")
local ChatWindowManager = require("senpai.presentation.chat.window_manager")

--- @module 'blink.cmp'
--- @class blink.cmp.Source
local M = {}

-- `opts` table comes from `sources.providers.your_provider.opts`
-- You may also accept a second argument `config`, to get the full
-- `sources.providers.your_provider` table
function M.new(opts)
  -- vim.validate("your_source.opts.some_option", opts.some_option, { "string" })
  -- vim.validate(
  --   "your_source.opts.optional_option",
  --   opts.optional_option,
  --   { "string" },
  --   true
  -- )

  local self = setmetatable({}, { __index = M })
  self.opts = opts
  return self
end

-- (Optional) Enable the source in specific contexts only
function M:enabled()
  return vim.bo.filetype == "senpai_chat_input"
end

-- (Optional) Non-alphanumeric characters that trigger the source
function M:get_trigger_characters()
  return { "/" }
end

function M:get_completions(ctx, callback)
  local trigger_char = ctx.trigger.character

  ---@type lsp.Range
  local delete_trigger_char = {
    -- 0 based index
    start = {
      line = ctx.bounds.line_number - 1,
      character = ctx.bounds.start_col - 2,
    },
    ["end"] = {
      line = ctx.bounds.line_number - 1,
      character = ctx.bounds.start_col - 1,
    },
  }

  --- @type lsp.CompletionItem[]
  local items = {}

  if trigger_char == "/" then
    items = vim
      .iter(SlashCommand.slash_commands)
      :map(
        ---@param label string
        ---@param command senpai.SlashCommand
        function(label, command)
          return {
            label = label,
            kind = require("blink.cmp.types").CompletionItemKind.Text,
            documentation = {
              kind = "plaintext",
              value = command.description,
            },
            textEdit = {
              newText = "",
              range = delete_trigger_char,
            },
            callback = command.callback,
          }
        end
      )
      :totable()
  end

  -- The callback _MUST_ be called at least once. The first time it's called,
  -- blink.cmp will show the results in the completion menu. Subsequent calls
  -- will append the results to the menu to support streamin results.
  callback({
    items = items,
    -- Whether blink.cmp should request items when deletin characters
    -- from the keyword (i.e. "foo|" -> "fo|")
    -- Note that any non-alphanumeric characters will always request
    -- new items (excluding `-` and `_`)
    is_incomplete_backward = false,
    -- Whether blink.cmp should request items when adding characters
    -- to the keyword (i.e. "fo|" -> "foo|")
    -- Note that any non-alphanumeric characters will always request
    -- new items (excluding `-` and `_`)
    is_incomplete_forward = false,
  })

  -- (Optional) Return a function which cancels the request
  -- If you have long running requests, it's essential you support cancellation
  return function() end
end

-- Called immediately after applying the item's textEdit/insertText
function M:execute(_, item, callback, default_implementation)
  -- By default, your source must handle the execution of the item itself,
  -- but you may use the default implementation at any time
  default_implementation()
  local item_callback = item.callback --[[@as string|fun():nil|nil]]
  if not item_callback then
    callback()
    return
  end
  if type(item_callback) == "function" then
    item_callback()
  elseif item_callback == "attach_file" then
    local chat = ChatWindowManager.get_current_chat()
    require("senpai.usecase.slash_command.attach_file").execute(chat)
  end

  -- The callback _MUST_ be called once
  callback()
end

return M
