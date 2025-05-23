local Config = require("senpai.config")
local ChatConfig = require("senpai.domain.config.chat")
local Text = require("nui.text")
local Line = require("nui.line")
local Menu = require("nui.menu")
local send_text = require("senpai.usecase.send_text")
local abort_request = require("senpai.usecase.abort_request")
local apply_replace_file = require("senpai.usecase.apply_replace_file")
local jump_to_block = require("senpai.usecase.jump_to_block")
local regist_url_at_rag = require("senpai.usecase.regist_url_at_rag")
local show_system_prompt = require("senpai.usecase.show_system_prompt")
local show_mcp_tools = require("senpai.usecase.show_mcp_tools")
local open_api_doc = require("senpai.usecase.open_api_doc")
local copy_input_or_codeblock =
  require("senpai.usecase.copy_input_or_codeblock")

---@class senpai.chat.Keymaps.keymaps

---@class senpai.chat.Keymaps
---@field chat senpai.IChatWindow
---@field common table<string, senpai.Config.chat.keymap>
---@field log_area table<string, senpai.Config.chat.keymap>
---@field input_area table<string, senpai.Config.chat.keymap>
local M = {}
M.__index = M

---@param chat senpai.ChatWindow
function M.new(chat)
  local self = setmetatable({}, M)
  self.chat = chat
  self:resolve_keys()
  return self
end

function M:show_help()
  local menu = Menu({
    relative = "editor",
    position = "50%",
    size = { width = 30 },
    border = {
      style = "rounded",
      padding = { 1, 2 },
      text = {
        top = "[senpai] help",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  }, {
    lines = self:create_items(),
    on_submit = function(keymap)
      local fun = keymap[1]()
      if fun then
        fun()
      end
    end,
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      close = { "<Esc>", "<C-c>", "q" },
      submit = { "<CR>", "<Space>" },
    },
  })
  menu:mount()
end

function M:execute_action(name)
  ---@type table<senpai.Config.chat.actions, function>
  local actions = {
    abort = function()
      abort_request.execute(self.chat)
    end,
    apply = function()
      apply_replace_file.execute(self.chat)
    end,
    close = function()
      self.chat:hide()
    end,
    copy_input_or_codeblock = function()
      copy_input_or_codeblock.execute(self.chat)
    end,
    jump_to_previous_block = function()
      jump_to_block.previous(self.chat)
    end,
    jump_to_next_block = function()
      jump_to_block.next(self.chat)
    end,
    load_thread = function()
      vim.cmd("Senpai loadThread")
    end,
    help = function()
      self:show_help()
    end,
    new_thread = function()
      vim.cmd("Senpai newThread")
    end,
    regist_url_at_rag = function()
      regist_url_at_rag.execute()
    end,
    open_api_doc = function()
      open_api_doc.execute()
    end,
    show_internal_log = function()
      if not Config.debug then
        vim.notify("[senpai] Set config to `debug=true`", vim.log.levels.INFO)
        return
      end
      if Config.internal_log then
        Config.internal_log:mount()
      end
    end,
    show_mcp_tools = function()
      show_mcp_tools.execute()
    end,
    show_system_prompt = function()
      show_system_prompt.execute(self.chat)
    end,
    submit = function()
      send_text.execute(self.chat)
    end,
    toggle_input = function()
      self.chat:toggle_input()
    end,
  }
  local action = actions[name]
  if action then
    action()
  else
    vim.notify("[senpai] There are no applicable actions.")
  end
end

---@param key string
---@param value string|senpai.Config.chat.keymap
---@return senpai.Config.chat.keymap
function M:resolve_key(key, value)
  if type(value) == "string" then
    return {
      function()
        self:execute_action(value)
      end,
      key = key,
      mode = "n",
      desc = value,
    }
  end
  return {
    value[1],
    key = key,
    mode = value.mode or "n",
    desc = value.desc,
  }
end

function M:resolve_keys()
  self.common = {}

  -- common
  for key, value in pairs(Config.chat.common.keymaps) do
    if value then
      self.common[key] = self:resolve_key(key, value)
    end
  end
  self.log_area = vim.deepcopy(self.common)
  self.input_area = vim.deepcopy(self.common)

  -- log
  for key, value in pairs(Config.chat.log_area.keymaps) do
    if value then
      self.log_area[key] = self:resolve_key(key, value)
    else
      self.log_area[key] = nil
      self.common[key] = nil
    end
  end

  -- input
  for key, value in pairs(Config.chat.input_area.keymaps) do
    if value then
      self.input_area[key] = self:resolve_key(key, value)
    else
      self.input_area[key] = nil
      self.common[key] = nil
    end
  end
end

---@param keymap senpai.Config.chat.keymap
local function create_item(keymap)
  if keymap.key == "" then
    return Menu.item(
      Line({
        Text(keymap.desc),
      }),
      keymap
    )
  end
  return Menu.item(
    Line({
      Text(keymap.key, "@constant.builtin"),
      Text(": " .. keymap.desc),
    }),
    keymap
  )
end

function M:create_items()
  local actions = vim.deepcopy(ChatConfig.actions)
  ---@type NuiTree.Node[]
  local items = {
    Menu.separator(
      Line({
        Text("j/k  q/<ESC>  "),
        Text("<CR>", "@constant.builtin"),
        Text(":execute"),
      }),
      { char = " " }
    ),
    Menu.separator(Text("common", "@markup.heading")),
  }
  for _, keymap in pairs(self.common) do
    table.insert(items, create_item(keymap))
    actions[keymap.desc] = true
  end

  table.insert(items, Menu.separator(Text("log area", "@markup.heading")))
  for key, keymap in pairs(self.log_area) do
    if not self.common[key] then
      table.insert(items, create_item(keymap))
      actions[keymap.desc] = true
    end
  end

  table.insert(items, Menu.separator(Text("input area", "@markup.heading")))
  for key, keymap in pairs(self.input_area) do
    if not self.common[key] then
      table.insert(items, create_item(keymap))
      actions[keymap.desc] = true
    end
  end

  table.insert(items, Menu.separator(Text("No keymap", "@markup.heading")))
  for action, value in pairs(actions) do
    if value then
      goto continue
    end
    table.insert(
      items,
      create_item({
        function()
          self:execute_action(action)
        end,
        key = "",
        desc = action,
      })
    )
    ::continue::
  end
  return items
end

return M
