local Config = require("senpai.config")
local WithDenops = require("senpai.presentation.shared.with_denops")
local Spinner = require("senpai.presentation.shared.spinner")
local Split = require("nui.split")
local Popup = require("nui.popup")

vim.treesitter.language.register("markdown", "senpai_chat_log")
vim.treesitter.language.register("markdown", "senpai_chat_input")

local win_options = {
  colorcolumn = "",
  number = false,
  relativenumber = false,
  signcolumn = "no",
  spell = false,
  statuscolumn = " ",
  wrap = true,
}

---@class senpai.ChatBuffer
---@field provider provider
---@field provider_config senpai.Config.providers.Provider
---@field system_prompt string
---@field thread_id string
---@field chat_log NuiSplit
---@field chat_input NuiSplit
---@field chat_border NuiPopup
---@field hidden boolean
local M = {}
M.__index = M

---@class senpai.ChatBufferNewArgs
---@field provider? provider
---@field provider_config? senpai.Config.providers.Provider
---@field system_prompt? string
---@field thread_id? string

---@param args senpai.ChatBufferNewArgs
---@return senpai.ChatBuffer
function M.new(args)
  args = args or {}
  local self = setmetatable({}, M)
  if args.provider and args.provider_config then
    self.provider = args.provider
    self.provider_config = args.provider_config
  else
    self.provider, self.provider_config = Config.get_provider()
  end

  self.thread_id = args.thread_id
    or vim.fn.getcwd() .. "-" .. os.date("%Y%m%d%H%M%S")

  self.system_prompt = args.system_prompt or ""

  -- TODO: 実際に描画するときだけ`createする`
  self.chat_log = self:create_chat_log()
  self.chat_log:mount()
  self.chat_input = self:create_chat_input()
  self.chat_input:mount()
  self.chat_border = self:create_chat_border()
  self.chat_border:mount()
  self.hidden = true
  return self
end

function M:create_chat_log()
  return Split({
    relative = "editor",
    position = "right",
    win_options = win_options,
    buf_options = {
      filetype = "senpai_chat_log",
    },
  })
end

function M:action_send()
  local lines = vim.api.nvim_buf_get_lines(self:get_input_buf(), 0, -1, false)
  vim.api.nvim_buf_set_lines(self:get_input_buf(), 0, -1, false, {})

  local spinner = Spinner.new(
    "AI thinking",
    -- update
    function(message)
      vim.api.nvim_win_set_config(self.chat_input.winid, { winbar = message })
    end,
    -- finish
    function(message)
      vim.api.nvim_win_set_config(self.chat_input.winid, { winbar = message })
      vim.defer_fn(function()
        vim.api.nvim_win_set_config(self.chat_input.winid, { winbar = "input" })
      end, 2000)
    end
  )
  spinner:start()
  WithDenops.wait_async_for_setup(function()
    vim.fn["denops#request_async"]("senpai", "chat", {
      {
        model = {
          provider = self.provider,
          provider_config = self.provider_config,
          system_prompt = self.system_prompt,
          thread_id = self.thread_id,
        },
        winid = self.chat_log.winid,
        bufnr = self:get_log_buf(),
        text = table.concat(lines, "\n"),
      },
    }, function()
      spinner:stop()
    end, function(e)
      spinner:stop(true)
      vim.notify(vim.inspect(e), vim.log.levels.ERROR)
    end)
  end)
end

function M:create_chat_input()
  return Split({
    relative = { type = "win", winid = self.chat_log.winid },
    position = "bottom",
    size = "40%",
    win_options = win_options,
    buf_options = {
      filetype = "senpai_chat_input",
    },
  })
end

function M:create_chat_border()
  local wininfo = vim.fn.getwininfo(self.chat_log.winid)[1]
  return Popup({
    position = {
      row = wininfo.height,
      col = 2,
    },
    size = {
      width = 20,
      height = 1,
    },
    enter = false,
    focusable = false,
    zindex = 50,
    relative = { type = "win", winid = self.chat_log.winid },
    border = {
      style = "none",
    },
    buf_options = {
      modifiable = true,
      readonly = false,
    },
  })
end

function M:show()
  self.chat_log:show()
  self.chat_input:show()
  self.chat_border:show()
  vim.api.nvim_set_current_buf(self.chat_input.bufnr)
  vim.cmd("normal G$")
  self.hidden = false
end

function M:hide()
  self.chat_log:hide()
  self.chat_input:hide()
  self.chat_border:hide()
  self.hidden = true
end

function M:destroy()
  self.chat_log:unmount()
  self.chat_input:unmount()
  self.chat_border:unmount()
  self.hidden = true
end

function M:toggle()
  if self.hidden then
    self:show()
  else
    self:hide()
  end
end

function M:get_log_buf()
  return self.chat_log.bufnr
end

function M:get_input_buf()
  return self.chat_input.bufnr
end

return M
