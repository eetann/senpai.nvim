local Config = require("senpai.config")
local WithDenops = require("senpai.presentation.shared.with_denops")
local Spinner = require("senpai.presentation.shared.spinner")

---@class senpai.Chat
---@field provider provider
---@field provider_config senpai.Config.providers.Provider
---@field system_prompt string
---@field thread_id string
---@field chat_log snacks.win
---@field chat_input snacks.win
---@field layout snacks.layout
local M = {}
M.__index = M

---@param provider? provider
---@param provider_config? senpai.Config.providers.Provider
---@param system_prompt? string
---@param thread_id? string
---@return senpai.Chat
function M.new(provider, provider_config, system_prompt, thread_id)
  local self = setmetatable({}, M)
  if provider and provider_config then
    self.provider = provider
    self.provider_config = provider_config
  else
    self.provider, self.provider_config = Config.get_provider()
  end
  if thread_id then
    self.thread_id = thread_id
  else
    self.thread_id = vim.fn.getcwd() .. "-" .. os.date("%Y%m%d%H%M%S")
  end
  if system_prompt then
    self.system_prompt = system_prompt
  end
  self.chat_log = self:create_chat_log()
  self.chat_input = self:create_chat_input()
  self.layout = self:create_layout()
  self:show()
  return self
end

---@return snacks.win.Config|{}
function M:get_win_options()
  return {
    backdrop = {
      bg = "NONE",
      blend = 100,
      transparent = true,
    },
    ---@type snacks.win.Keys[]
    keys = {
      q = function()
        self.layout:close()
      end,
    },
    wo = {
      colorcolumn = "",
      number = false,
      relativenumber = false,
      signcolumn = "no",
      spell = false,
      statuscolumn = " ",
      winhighlight = "Normal:NONE,NormalNC:NONE,WinBar:SnacksWinBar,WinBarNC:SnacksWinBarNC",
      wrap = true,
    },
    ft = "markdown",
  }
end

function M:create_chat_log()
  return require("snacks").win(
    vim.tbl_deep_extend("force", self:get_win_options(), {
      bo = {
        filetype = "senpai_chat_log",
      },
    })
  )
end

function M:action_send()
  local lines = vim.api.nvim_buf_get_lines(self:get_input_buf(), 0, -1, false)
  vim.api.nvim_buf_set_lines(self:get_input_buf(), 0, -1, false, {})

  local spinner = Spinner.new("AI thinking")
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
        bufnr = self:get_log_buf(),
        text = table.concat(lines, "\n"),
      },
    }, function()
      spinner:stop()
    end, function()
      spinner:stop(true)
    end)
  end)
end

function M:create_chat_input()
  return require("snacks").win(
    vim.tbl_deep_extend("force", self:get_win_options(), {
      bo = {
        filetype = "senpai_chat_input",
      },
      ---@type snacks.win.Keys[]
      keys = {
        ["<CR><CR>"] = function(win)
          self:action_send()
        end,
      },
    })
  )
end

function M:create_layout()
  return require("snacks.layout").new({
    wins = {
      chat_log = self.chat_log,
      input = self.chat_input,
    },
    layout = {
      box = "vertical",
      width = 0.3,
      min_width = 50,
      height = 0.8,
      position = "right",
      {
        win = "chat_log",
        title = "Senpai",
        title_pos = "center",
        border = "top",
      },
      {
        win = "input",
        title = "input",
        title_pos = "center",
        border = "top",
        height = 0.3,
      },
    },
  })
end

function M:show()
  self.layout:show()
end

function M:hide()
  self.layout:hide()
end

function M:close()
  self.layout:close()
end

function M:toggle_input()
  self.layout:toggle("chat_input")
end

function M:get_log_buf()
  return self.chat_log.buf
end

function M:get_input_buf()
  return self.chat_input.buf
end

return M
