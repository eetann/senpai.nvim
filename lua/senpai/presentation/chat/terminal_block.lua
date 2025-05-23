local n = require("nui-components")
local Columns = require("nui-components.columns")
local Button = require("nui-components.button")
local Gap = require("nui-components.gap")
local IBlock = require("senpai.domain.i_block")
local utils = require("senpai.usecase.utils")
local Popup = require("nui.popup")
local Config = require("senpai.config")

---@class senpai.TerminalBlock: senpai.ITerminalBlock
local M = {}
M.__index = M
setmetatable(M, { __index = IBlock })

---@param opts { winid:integer, bufnr:integer, row:integer }
---@return senpai.TerminalBlock
function M.new(opts)
  local self = setmetatable({}, M)
  self.block_type = "terminal"
  self.row = opts.row
  self.winid = opts.winid
  self.bufnr = opts.bufnr
  self:setup()

  return self
end

function M:setup_body()
  local signal = n.create_signal({
    hidden = true,
  })
  self.body = Columns({
    flex = 1,
    children = {
      Button({
        align = "center",
        label = "Run",
        flex = 1,
        on_press = function()
          vim.api.nvim_set_current_win(self.winid)
          vim.print("run")
          self:execute_command_in_term()
          signal.hidden = false
          self.renderer:redraw()
        end,
        mappings = function()
          return {
            {
              mode = "n",
              key = "<S-Tab>",
              handler = function()
                utils.safe_set_current_win(
                  self.winid,
                  { row = self.row, col = 0 }
                )
              end,
            },
          }
        end,
      }),
      Gap({ size = 1 }, { zindex = 49 }),
      Button({
        label = "Open output",
        hidden = signal.hidden,
        flex = 1,
        align = "center",
        on_press = function()
          self:open_result_popup()
        end,
      }),
      Gap({ size = 1 }, { zindex = 49 }),
      Button({
        label = "Reject",
        flex = 1,
        align = "center",
        on_press = function()
          vim.api.nvim_set_current_win(self.winid)
          vim.print("reject")
        end,
        mappings = function()
          return {
            {
              mode = "n",
              key = "<Tab>",
              handler = function()
                utils.safe_set_current_win(
                  self.winid,
                  { row = self.row + 1, col = 0 }
                )
              end,
            },
          }
        end,
      }),
    },
  }, {
    zindex = 50,
  })
end

function M:open_result_popup()
  local popup = Popup({
    bufnr = self.term_bufnr,
    relative = {
      type = "buf",
      position = {
        row = self.row - 1,
        col = 0,
      },
    },
    position = 1,
    size = {
      width = M.get_adjust_width(self.winid),
      height = 5,
    },
    border = {
      style = "rounded",
    },
    enter = true,
  })
  popup:mount()
  popup:map("n", "<esc>", function()
    popup:unmount()
  end)
  popup:map("n", "q", function()
    popup:unmount()
  end)
end

function M:execute_command_in_term()
  if self.term_bufnr and vim.api.nvim_buf_is_valid(self.term_bufnr) then
    vim.api.nvim_buf_delete(self.term_bufnr, { force = true })
  end
  self.term_bufnr = vim.api.nvim_create_buf(false, true)
  self.term_id = vim.api.nvim_open_term(self.term_bufnr, {
    on_input = function(_, _, _, data)
      pcall(vim.api.nvim_chan_send, self.job_id, data)
    end,
  })
  self.job_id = vim.fn.jobstart(self.command, {
    on_stdout = function(_, data)
      pcall(vim.api.nvim_chan_send, self.term_id, table.concat(data, "\r\n"))
    end,
    on_stderr = function(_, data)
      pcall(vim.api.nvim_chan_send, self.term_id, table.concat(data, "\r\n"))
    end,
    on_exit = function(_, code)
      pcall(
        vim.api.nvim_chan_send,
        self.term_id,
        string.format("\r\n[Process exited %d]\r\n", code)
      )
      self.job_id = nil
    end,
  })
end

-- local block = M.new({
--   winid = vim.api.nvim_get_current_win(),
--   bufnr = vim.api.nvim_get_current_buf(),
--   row = 2,
-- })
-- block.command = "echo hello"
-- block:mount()
return M
