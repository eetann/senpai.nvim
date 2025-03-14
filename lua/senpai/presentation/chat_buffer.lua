local Config = require("senpai.config")
local WithDenops = require("senpai.presentation.shared.with_denops")
local Spinner = require("senpai.presentation.shared.spinner")
local Split = require("nui.split")

vim.treesitter.language.register("markdown", "senpai_chat_log")
vim.treesitter.language.register("markdown", "senpai_chat_input")

local function create_winbar_text(text)
  return "%#Nomal#%=" .. text .. "%="
end

local win_options = {
  colorcolumn = "",
  number = false,
  relativenumber = false,
  signcolumn = "no",
  spell = false,
  statuscolumn = "",
  wrap = true,
  fillchars = "eob: ,lastline:…",
}

---@class senpai.ChatBuffer
---@field provider provider
---@field provider_config senpai.Config.providers.Provider
---@field system_prompt string
---@field thread_id string
---@field chat_log NuiSplit|nil
---@field chat_input NuiSplit|nil
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

  self.hidden = true
  return self
end

function M:create_chat_log()
  self.chat_log = Split({
    relative = "editor",
    position = "right",
    win_options = vim.tbl_deep_extend("force", win_options, {
      winbar = create_winbar_text("Conversations with Senpai"),
    }),
    buf_options = {
      filetype = "senpai_chat_log",
    },
  })
  self.chat_log:map("n", "q", function()
    self:hide()
  end)
end

function M:action_send()
  local lines = vim.api.nvim_buf_get_lines(self:get_input_buf(), 0, -1, false)
  vim.api.nvim_buf_set_lines(self:get_input_buf(), 0, -1, false, {})

  local spinner = Spinner.new(
    "Senpai thinking",
    -- update
    function(message)
      vim.api.nvim_set_option_value(
        "winbar",
        create_winbar_text(message),
        { win = self.chat_input.winid }
      )
    end,
    -- finish
    function(message)
      vim.api.nvim_set_option_value(
        "winbar",
        create_winbar_text(message),
        { win = self.chat_input.winid }
      )
      vim.defer_fn(function()
        vim.api.nvim_set_option_value(
          "winbar",
          create_winbar_text("Ask Senpai"),
          { win = self.chat_input.winid }
        )
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
  self.chat_input = Split({
    relative = "win",
    position = "bottom",
    size = "40%",
    win_options = vim.tbl_deep_extend("force", win_options, {
      winbar = create_winbar_text("Ask Senpai"),
    }),
    buf_options = {
      filetype = "senpai_chat_input",
    },
  })
  self.chat_input:map("n", "<CR><CR>", function()
    self:action_send()
  end)
  self.chat_input:map("n", "q", function()
    self:hide()
  end)
end

function M:show()
  if not self.chat_log then
    self:create_chat_log()
    self.chat_log:mount()
  end
  self.chat_log:show()

  if not self.chat_input then
    self:create_chat_input()
    self.chat_input:mount()
  else
    self.chat_input:update_layout({
      relative = "win",
      position = "bottom",
    })
  end
  self.chat_input:show()

  vim.api.nvim_set_current_buf(self.chat_input.bufnr)
  vim.cmd("normal G$")
  self.hidden = false
end

function M:hide()
  self.chat_log:hide()
  self.chat_input:hide()
  self.hidden = true
end

function M:destroy()
  self.chat_log:unmount()
  self.chat_input:unmount()
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
