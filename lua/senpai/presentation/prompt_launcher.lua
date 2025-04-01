local Config = require("senpai.config")
local ChatWindowManager = require("senpai.presentation.chat.window_manager")
local send_text = require("senpai.usecase.send_text")
local resolve_prompt_launcher =
  require("senpai.usecase.resolve_prompt_launcher")

local M = {}

local function make_item_text(launcher)
  return launcher.name
end

---@param launcher senpai.Config.PromptLauncher.launcher
local function launch(launcher)
  local resolved_launcher = resolve_prompt_launcher.execute(launcher)
  ChatWindowManager.replace_new_thread(resolved_launcher)
  local chat = ChatWindowManager.get_current_chat()
  if chat then
    send_text.execute(chat, resolved_launcher.user_prompt)
  end
end

---@class _.launcher_item: senpai.Config.PromptLauncher.launcher
---@field name string

---@param items _.launcher_item[]
local function load_launchers_native(items)
  vim.ui.select(items, {
    prompt = "Select launcher",
    format_item = make_item_text,
  }, function(item)
    if item then
      launch(item)
    end
  end)
end

--[=[@doc
  category = "api"
  name = "prompt_launcher"
  desc = """
```lua
senpai.prompt_launcher()
```
Select and launch the prompt_launcher set in \|senpai.Config.prompt_launchers\|.
"""
--]=]
function M.prompt_launcher()
  local launchers = Config.prompt_launchers or {}
  ---@type _.launcher_item[]
  local items = {}

  for key, launcher in pairs(launchers) do
    ---@class _.launcher_item
    local new_launcher = vim.deepcopy(launcher)
    new_launcher.name = key
    new_launcher.priority = launcher.priority or 50
    table.insert(items, new_launcher)
  end
  table.sort(items, function(a, b)
    return a.priority < b.priority
  end)

  load_launchers_native(items)
end

return M
