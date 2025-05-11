local Config = require("senpai.config")
local Split = require("nui.split")
local utils = require("senpai.usecase.utils")
local set_messages = require("senpai.usecase.set_messages")
local Keymaps = require("senpai.presentation.chat.keymaps")
local IChatWindow = require("senpai.domain.i_chat_window")
local StickyPopupManager =
  require("senpai.presentation.chat.sticky_popup_manager")

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
  fillchars = "eob: ",
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
    self.is_new = args.thread_id:find("^test_render.*") and true or false
  else
    self.thread_id = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
      .. "-"
      .. os.date("%Y%m%d%H%M%S")
    self.is_new = true
  end

  self.system_prompt = ""
  if args.system_prompt then
    self.system_prompt = args.system_prompt
  elseif Config.chat.system_prompt then
    self.system_prompt = Config.chat.system_prompt
  end

  self.is_sending = false
  self.is_first_message = true
  self.edit_file_results = {}
  self.replace_file_results = {}
  return self
end

---@param area NuiSplit
---@param keymaps table<string, senpai.Config.chat.keymap>
function M:apply_keymaps(area, keymaps)
  for key, value in pairs(keymaps) do
    if type(value.mode) == "string" then
      area:map(value.mode--[[@as string]], key, value[1])
    else
      for _, mode in
        pairs(value.mode--[=[@as string[]]=])
      do
        area:map(mode, key, value[1])
      end
    end
  end
end

--- @param keymaps table<string, senpai.Config.chat.keymap>
function M:create_log_area(keymaps)
  self.log_area = Split({
    relative = "editor",
    position = "right",
    size = Config.chat.common.width or 80,
    win_options = vim.tbl_deep_extend("force", win_options, {
      winbar = create_winbar_text("Conversations with Senpai"),
      conceallevel = 3,
    }),
    buf_options = {
      filetype = "senpai_chat_log",
    },
  })
  self:apply_keymaps(self.log_area, keymaps)
end

---@param keymaps table<string, senpai.Config.chat.keymap>
function M:create_input_area(keymaps)
  self.input_area = Split({
    relative = "win",
    position = "bottom",
    size = Config.chat.input_area.height or "25%",
    win_options = vim.tbl_deep_extend("force", win_options, {
      winbar = create_winbar_text(IChatWindow.input_winbar_text),
    }),
    buf_options = {
      filetype = "senpai_chat_input",
    },
  })
  self:apply_keymaps(self.input_area, keymaps)
end

function M:setup_log_area(winid)
  if winid then
    self.log_area.winid = winid
    vim.api.nvim_win_set_buf(self.log_area.winid, self.log_area.bufnr)
    --- @diagnostic disable-next-line: invisible
    for name, value in pairs(self.log_area._.win_options) do
      vim.api.nvim_set_option_value(
        name,
        value,
        { scope = "local", win = self.log_area.winid }
      )
    end
    vim.api.nvim_set_current_win(self.log_area.winid)
  end
  self.sticky_popup_manager =
    StickyPopupManager.new(self.log_area.winid, self.log_area.bufnr)
end

function M:display_chat_info()
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
end

---@param winid? number
function M:show(winid)
  local resolved_keymaps
  if
    not self.log_area or not vim.api.nvim_buf_is_loaded(self.log_area.bufnr)
  then
    resolved_keymaps = Keymaps.new(self)
    self:create_log_area(resolved_keymaps.log_area)
    if winid then
      self:setup_log_area(winid)
    end
    self.log_area:mount()
    self.sticky_popup_manager =
      StickyPopupManager.new(self.log_area.winid, self.log_area.bufnr)
    self:display_chat_info()
    if not self.is_new then
      set_messages.execute(self)
    end
  else
    self.log_area:show()
    self.sticky_popup_manager:remount(self.log_area.winid)
  end

  if
    not self.input_area or not vim.api.nvim_buf_is_loaded(self.input_area.bufnr)
  then
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
  self.sticky_popup_manager:close_all_popup()
  self.log_area:hide()
  self.input_area:hide()
end

function M:destroy()
  self.log_area:unmount()
  self.input_area:unmount()
end

function M:is_hidden()
  local winid = self.log_area.winid
  if winid and vim.api.nvim_win_is_valid(winid) then
    return false
  end
  return true
end

function M:toggle()
  if self:is_hidden() then
    self:show()
  else
    self:hide()
  end
end

function M:toggle_input()
  local winid = self.input_area.winid
  if
    not self.input_area or not vim.api.nvim_buf_is_loaded(self.input_area.bufnr)
  then
    local resolved_keymaps = Keymaps.new(self)
    self:create_input_area(resolved_keymaps.input_area)
    self.input_area:mount()
  elseif winid and vim.api.nvim_win_is_valid(winid) then
    self.input_area:hide()
  else
    self.input_area:show()
  end
end

function M:add_diff_popup(row, path)
  if not self.sticky_popup_manager then
    self.sticky_popup_manager =
      StickyPopupManager.new(self.log_area.winid, self.log_area.bufnr)
  end
  return self.sticky_popup_manager:add_float_popup(row, path)
end

return M
