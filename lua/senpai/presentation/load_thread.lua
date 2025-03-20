local get_threads = require("senpai.usecase.get_threads")
local ChatWindowManager = require("senpai.presentation.chat.window_manager")
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
  ChatWindowManager.replace_new_chat(args)
end

--[=[@doc
  category = "api"
  name = "load_thread"
  desc = """
  ```lua
  senpai.load_thread()
  ````
  detail -> |senpai-feature-history|
  """
--]=]
function M.load_thread()
  get_threads.execute(function(threads)
    local ok, picker = pcall(require, "snacks.picker")
    if not ok then
      vim.ui.select(threads, {
        prompt = "Select Thread",
        format_item = make_item_text,
      }, function(thread)
        show_thread(thread)
      end)
    else
      picker({
        ---@return snacks.picker.Item[]
        finder = function()
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
      })
    end
  end)
end

return M
