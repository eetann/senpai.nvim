local get_threads = require("senpai.usecase.request.get_threads")
local ChatWindowManager = require("senpai.presentation.chat.window_manager")
local delete_threads = require("senpai.usecase.request.delete_threads")
local Spinner = require("senpai.presentation.shared.spinner")
local get_thread_by_id = require("senpai.usecase.request.get_thread_by_id")
local M = {}

local function extract_directory_path(path)
  local dir_part = path:match("(.+)%-[0-9]+$")
  return vim.fn.fnamemodify(dir_part or path, ":~")
end

local function get_score(updated_date)
  local digit = string.gsub(updated_date, "[^0-9]", "")
  return tonumber(digit)
end

---make item title for fuzzy finder
---@param thread senpai.chat.thread
local function make_item_text(thread)
  local text = extract_directory_path(thread.id)
  if thread.title then
    text = text .. ": " .. thread.title
  end
  return text
end

---@param thread senpai.chat.thread
local function show_thread(thread)
  local args = {
    thread_id = thread.id,
  }
  if thread.metadata then
    args.provider = thread.metadata.provider
    args.system_prompt = thread.metadata.system_prompt
  end
  ChatWindowManager.replace_new_thread(args)
end

local function load_thread_native()
  local threads = get_threads.execute()
  vim.ui.select(threads, {
    prompt = "Select Thread",
    format_item = make_item_text,
  }, function(thread)
    show_thread(thread)
  end)
end

local function load_thread_snacks()
  require("snacks.picker")({
    ---@return snacks.picker.Item[]
    finder = function()
      local spinner = Spinner.new("[senpai] I'm trying to remember...")
      spinner:start()
      local threads = get_threads.execute()
      spinner:stop()
      local items = {}
      local i = 1
      for _, thread in pairs(threads) do
        ---@return snacks.picker.Item
        local item = {
          idx = i,
          score = get_score(thread.updatedAt),
          text = make_item_text(thread),
          preview = { text = vim.inspect(thread), ft = "lua" },
          thread = thread,
        }
        table.insert(items, item)
        i = i + 1
      end
      return items
    end,
    ---@type snacks.picker.Action.spec
    confirm = function(the_picker, choice)
      the_picker:close()
      show_thread(choice.thread)
    end,
    format = "text",
    preview = "preview",
    win = {
      input = {
        keys = {
          ["dd"] = { "delete_thread", mode = { "n" } },
        },
      },
    },
    actions = {
      delete_thread = function(the_picker)
        the_picker.preview:reset()
        for _, item in ipairs(the_picker:selected({ fallback = true })) do
          local thread = item.thread
          ---@cast thread senpai.chat.thread
          if thread then
            delete_threads.execute(thread.id, function()
              vim.notify(
                "[senpai] Successfully deleted thread:\n" .. thread.title
              )
            end)
          end
        end
        the_picker.list:set_selected()
        the_picker.list:set_target()
        the_picker:find()
      end,
    },
  })
end

--[=[@doc
  category = "api"
  name = "load_thread"
  desc = """
```lua
senpai.load_thread()
senpai.load_thread(thread)
```
detail -> |senpai-feature-history|
"""

  [[args]]
  name = "thread_id"
  type = "string?"
  desc = """
If you do not specify the id of the thread you want to read, the finder will open.
"""
--]=]
---@param thread_id? string
function M.load_thread(thread_id)
  if thread_id then
    local thread = get_thread_by_id.execute(thread_id)
    show_thread(thread)
    return
  end
  local ok, _ = pcall(require, "snacks.picker")
  if not ok then
    load_thread_native()
  else
    load_thread_snacks()
  end
end

return M
