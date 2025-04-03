local Config = require("senpai.config")
local Split = require("nui.split")
local utils = require("senpai.usecase.utils")
local set_messages = require("senpai.usecase.set_messages")
local Keymaps = require("senpai.presentation.chat.keymaps")

vim.treesitter.language.register("markdown", "senpai_chat_log")
vim.treesitter.language.register("markdown", "senpai_chat_input")

local function create_winbar_text(text)
  return "%#Nomal#%=" .. text .. "%="
end

local win_options = {
  colorcolumn = "",
  number = false,
  relativenumber = false,
  signcolumn = "yes",
  spell = false,
  statuscolumn = "",
  wrap = true,
  fillchars = "eob: ,lastline:…",
  -- listchars = "eol: ",
}

---@class senpai.ChatWindow: senpai.IChatWindow
---@field is_new boolean
local M = {}
M.__index = M

-- TODO: nuiのlayoutへ置き換える

---@param args senpai.ChatWindowNewArgs
---@return senpai.ChatWindow|nil
function M.new(args)
  args = args or {}
  local self = setmetatable({}, M)
  local provider = Config.get_provider(args.provider)
  if not provider then
    return
  end
  self.provider = provider

  if args.thread_id then
    self.thread_id = args.thread_id
    self.is_new = false
  else
    self.thread_id = vim.fn.getcwd() .. "-" .. os.date("%Y%m%d%H%M%S")
    self.is_new = true
  end

  self.system_prompt = ""
  if args.system_prompt then
    self.system_prompt = args.system_prompt
  elseif Config.chat.system_prompt then
    self.system_prompt = Config.chat.system_prompt
  end

  self.is_sending = false
  self.edit_file_results = {}
  self.replace_file_results = {}
  return self
end

--- @param keymaps table<string, senpai.Config.chat.keymap>
function M:create_log_area(keymaps)
  self.log_area = Split({
    relative = "editor",
    position = "right",
    win_options = vim.tbl_deep_extend("force", win_options, {
      winbar = create_winbar_text("Conversations with Senpai"),
    }),
    buf_options = {
      filetype = "senpai_chat_log",
    },
  })
  for key, value in pairs(keymaps) do
    if type(value.mode) == "string" then
      self.log_area:map(value.mode--[[@as string]], key, value[1])
    else
      for _, mode in
        pairs(value.mode--[=[@as string[]]=])
      do
        self.log_area:map(mode, key, value[1])
      end
    end
  end
end

---@param keymaps table<string, senpai.Config.chat.keymap>
function M:create_input_area(keymaps)
  self.input_area = Split({
    relative = "win",
    position = "bottom",
    size = "25%",
    win_options = vim.tbl_deep_extend("force", win_options, {
      winbar = create_winbar_text("Ask Senpai"),
    }),
    buf_options = {
      filetype = "senpai_chat_input",
    },
  })
  for key, value in pairs(keymaps) do
    if type(value.mode) == "string" then
      self.input_area:map(value.mode--[[@as string]], key, value[1])
    else
      for _, mode in
        pairs(value.mode--[=[@as string[]]=])
      do
        self.input_area:map(mode, key, value[1])
      end
    end
  end
end

---@param winid? number
function M:show(winid)
  local resolved_keymaps
  if not self.log_area then
    resolved_keymaps = Keymaps.new(self)
    self:create_log_area(resolved_keymaps.log_area)
    if winid then
      self.log_area.winid = winid
      vim.api.nvim_win_set_buf(self.log_area.winid, self.log_area.bufnr)
      ---@diagnostic disable-next-line: invisible
      for name, value in pairs(self.log_area._.win_options) do
        vim.api.nvim_set_option_value(
          name,
          value,
          { scope = "local", win = self.log_area.winid }
        )
      end
      vim.api.nvim_set_current_win(self.log_area.winid)
    end
    self.log_area:mount()
    utils.set_text_at_last(
      self.log_area.bufnr,
      string.format(
        [[
---
name: "%s"
model_id: "%s"
thread_id: "%s"
---
]],
        self.provider.name,
        self.provider.model_id,
        self.thread_id
      )
    )
    if not self.is_new then
      set_messages.execute(self)
    end
  else
    self.log_area:show()
  end

  if not self.input_area then
    if not resolved_keymaps then
      resolved_keymaps = Keymaps.new(self)
    end
    self:create_input_area(resolved_keymaps.input_area)
    self.input_area:mount()
  else
    self.input_area:update_layout({
      relative = "win",
      position = "bottom",
    })
    self.input_area:show()
  end

  vim.api.nvim_set_current_buf(self.input_area.bufnr)
  vim.cmd("normal G$")
end

function M:hide()
  self.log_area:hide()
  self.input_area:hide()
end

function M:destroy()
  self.log_area:unmount()
  self.input_area:unmount()
end

function M:toggle()
  local winid = self.log_area.winid
  if winid and vim.api.nvim_win_is_valid(winid) then
    self:hide()
  else
    self:show()
  end
end

function M:toggle_input()
  local winid = self.input_area.winid
  if winid and vim.api.nvim_win_is_valid(winid) then
    self.input_area:hide()
  else
    self.input_area:show()
  end
end

return M
