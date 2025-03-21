local Config = require("senpai.config")
local Menu = require("nui.menu")

local M = {}

function M.execute()
  local menu = Menu({
    position = "50%",
    size = {
      width = 25,
    },
    border = {
      style = "single",
      padding = { 1, 2 },
      text = {
        top = "[senapi] help",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  }, {
    lines = M.create_items(),
    on_submit = function(item)
      print("SUBMITTED", vim.inspect(item))
    end,
  })
  menu:mount()
end

---@param key string
---@param value string|senpai.Config.chat.keymap
---@return table
local function resolve_key(key, value)
  if type(value) == "string" then
    return {
      function()
        -- TODO: ここでusecaseを呼ぶ
        vim.print("foooooo")
      end,
      key = key,
      mode = "n",
      desc = "TODO",
    }
  end
  ---@cast value senpai.Config.chat.keymap
  return {
    value[1],
    key = key,
    mode = value.mode or "n",
    desc = value.desc,
  }
end

---@return senpai.Config.chat
function M.resolve_keys()
  ---@type senpai.Config.chat
  local resolved = {
    log_area = { keymaps = {} },
    input_area = { keymaps = {} },
  }

  ---@type senpai.Config.chat.keymap[]
  local common_keys = {}
  for key, value in pairs(Config.chat.common.keymaps) do
    if value then
      table.insert(common_keys, resolve_key(key, value))
    end
  end

  resolved.log_area.keymaps = vim.deepcopy(common_keys)
  for key, value in pairs(Config.chat.log_area.keymaps) do
    if value then
      table.insert(resolved.log_area.keymaps, resolve_key(key, value))
    else
      resolved.log_area.keymaps[key] = nil
    end
  end

  resolved.input_area.keymaps = vim.deepcopy(common_keys)
  for key, value in pairs(Config.chat.input_area.keymaps) do
    if value then
      table.insert(resolved.input_area.keymaps, resolve_key(key, value))
    else
      resolved.input_area.keymaps[key] = nil
    end
  end
  return resolved
end

---@chat_config senpai.Config.chat
function M.create_items(chat_config)
  ---@type NuiTree.Node[]
  local items = {}
  for _, value in pairs(chat_config.log_area.keymaps) do
    -- NuiLine?
  end
  return items
end

return M
