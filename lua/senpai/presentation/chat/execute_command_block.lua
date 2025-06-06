local IBlock = require("senpai.domain.i_block")
local utils = require("senpai.usecase.utils")

---@class senpai.ExecuteCommandBlock: senpai.IExecuteCommandBlock
local M = {}
M.__index = M
setmetatable(M, { __index = IBlock })

---@param opts { winid:integer, bufnr:integer, command: string, row:integer|nil }
---@return senpai.ExecuteCommandBlock
function M.new(opts)
  local self = setmetatable({}, M)
  self.block_type = "execute_command"
  self.command = opts.command
  local row = opts.row or vim.api.nvim_buf_line_count(opts.bufnr)
  self.row = row
  self.winid = opts.winid
  self.bufnr = opts.bufnr
  -- UI-less block, no need to setup or mount
  utils.replace_lines_at_last(self.bufnr, {
    "> [!NOTE] ExecuteCommand",
    "> ```sh",
    "> " .. self.command,
    "> ```",
    "",
  })

  return self
end

---Override has_ui to return false for UI-less block
---@return boolean
function M:has_ui()
  return false
end

-- Note: Result popup functionality should be handled by window.lua if needed

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

  self.output_lines = {}

  self.job_id = vim.fn.jobstart(self.command, {
    on_stdout = function(_, data)
      pcall(vim.api.nvim_chan_send, self.term_id, table.concat(data, "\r\n"))

      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(self.output_lines, line)
        end
      end
    end,
    on_stderr = function(_, data)
      pcall(vim.api.nvim_chan_send, self.term_id, table.concat(data, "\r\n"))

      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(self.output_lines, "STDERR: " .. line)
        end
      end
    end,
    on_exit = function(_, code)
      pcall(
        vim.api.nvim_chan_send,
        self.term_id,
        string.format("\r\n[Process exited %d]\r\n", code)
      )

      table.insert(self.output_lines, string.format("[Process exited %d]", code))

      self.job_id = nil
      self.exit_code = code
    end,
  })
end

---@return { label: string, action_type: string, enabled?: boolean }[]
function M:get_action_buttons()
  if not self.term_bufnr then
    return {
      { label = "Run",    action_type = "run",    enabled = true },
      { label = "Reject", action_type = "reject", enabled = true },
    }
  else
    return {
      { label = "Accept", action_type = "accept", enabled = true },
      { label = "Reject", action_type = "reject", enabled = true },
    }
  end
end

---@param action_type string
---@param user_input? string
---@return { success: boolean, message: string }
function M:handle_action(action_type, user_input)
  if action_type == "run" then
    -- Execute the command
    self:execute_command_in_term()

    -- Wait for command to complete
    vim.wait(60 * 1000, function()
      return self.exit_code ~= nil
    end)

    -- Get the output from accumulated lines
    local message = "Executed command: " .. self.command
    if self.output_lines and #self.output_lines > 0 then
      message = message .. "\n\nOutput:\n" .. table.concat(self.output_lines, "\n")
    end
    if user_input and user_input ~= "" then
      message = message .. "\n\n" .. user_input
    end

    return { success = true, message = message }
  elseif action_type == "accept" then
    local message = "Accepted command execution results for: " .. self.command
    if self.output_lines and #self.output_lines > 0 then
      message = message .. "\n\nOutput:\n" .. table.concat(self.output_lines, "\n")
    end
    if self.exit_code then
      message = message .. "\n\nExit code: " .. tostring(self.exit_code)
    end
    if user_input and user_input ~= "" then
      message = message .. "\n\n" .. user_input
    end

    return { success = true, message = message }
  elseif action_type == "reject" then
    local message = "Rejected command: " .. self.command
    if user_input and user_input ~= "" then
      message = message .. "\n\n" .. user_input
    end
    return { success = true, message = message }
  else
    return { success = false, message = "Unknown action type: " .. action_type }
  end
end

-- local block = M.new({
--   winid = vim.api.nvim_get_current_win(),
--   bufnr = vim.api.nvim_get_current_buf(),
--   row = 2,
-- })
-- block.command = "echo hello"
-- block:mount()
return M
