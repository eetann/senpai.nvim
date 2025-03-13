local Config = require("senpai.config")
local WithDenops = require("senpai.presentation.shared.with_denops")
local Spinner = require("senpai.presentation.shared.spinner")

---@class senpai.ChatBuffer
---@field provider provider
---@field provider_config senpai.Config.providers.Provider
---@field system_prompt string
---@field thread_id string
---@field chat_log snacks.win
---@field chat_input snacks.win
---@field layout snacks.layout
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

  self.chat_log = self:create_chat_log()
  self.chat_input = self:create_chat_input()
  self.layout = self:create_layout()
  self.hidden = true
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
        self:hide()
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

  local spinner = Spinner.new(
    "AI thinking",
    -- update
    function(message)
      self.chat_input:set_title(message)
    end,
    -- finish
    function(message)
      self.chat_input:set_title(message)
      vim.defer_fn(function()
        self.chat_input:set_title("input")
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
        winid = self.chat_log.win,
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
  return require("snacks").win(
    vim.tbl_deep_extend("force", self:get_win_options(), {
      bo = {
        filetype = "senpai_chat_input",
      },
      ---@type snacks.win.Keys[]
      keys = {
        ["<CR><CR>"] = function()
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
      width = 0.4,
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
  self.chat_input:focus()
  vim.cmd("normal G$")
  self.hidden = false
end

function M:hide()
  for _, win in pairs(self.layout.wins) do
    win:close({ buf = false })
  end
  for _, win in pairs(self.layout.box_wins) do
    win:close({ buf = false })
  end
  self.hidden = true
end

function M:destroy()
  self.layout:close()
  self.hidden = true
end

function M:toggle_input()
  self.layout:toggle("chat_input")
end

function M:toggle()
  if self.hidden then
    self:show()
  else
    self:hide()
  end
end

function M:get_log_buf()
  return self.chat_log.buf
end

function M:get_input_buf()
  return self.chat_input.buf
end

return M
