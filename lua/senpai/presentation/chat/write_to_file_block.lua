local IBlock = require("senpai.domain.i_block")
local utils = require("senpai.usecase.utils")

---@class senpai.WriteToFileBlock: senpai.IBlock
---@field block_type "write_to_file"
---@field path string
---@field content string
local M = {}
M.__index = M
setmetatable(M, { __index = IBlock })

---@param opts { winid:integer, bufnr:integer, path: string, content: string, row:integer|nil }
---@return senpai.WriteToFileBlock
function M.new(opts)
  local self = setmetatable({}, M)
  self.block_type = "write_to_file"
  self.path = opts.path
  self.content = opts.content
  local row = opts.row or vim.api.nvim_buf_line_count(opts.bufnr)
  self.row = row
  self.winid = opts.winid
  self.bufnr = opts.bufnr
  
  -- UI-less block, no need to setup or mount
  local filetype = utils.get_filetype(self.path)
  
  -- Split content into lines and prefix each with "> "
  local content_lines = vim.split(self.content, "\n", { plain = true })
  for i, line in ipairs(content_lines) do
    content_lines[i] = "> " .. line
  end
  
  local lines = {
    "",
    "> [!NOTE] WriteToFile",
    "> " .. self.path,
    "> ```" .. filetype,
  }
  
  -- Add content lines
  for _, line in ipairs(content_lines) do
    table.insert(lines, line)
  end
  
  table.insert(lines, "> ```")
  table.insert(lines, "")
  
  utils.replace_lines_at_last(self.bufnr, lines)

  return self
end

---Override has_ui to return false for UI-less block
---@return boolean
function M:has_ui()
  return false
end

---@return { label: string, action_type: string, approve: boolean }[]
function M:get_action_buttons()
  return {
    { label = "Accept", action_type = "accept", approve = true },
    { label = "Reject", action_type = "reject", approve = false },
  }
end

---@param action_type string
---@return { success: boolean, message: string }
function M:handle_action(action_type)
  if action_type == "accept" then
    local success, error_msg = pcall(function()
      -- Create directory if it doesn't exist
      local dir = vim.fn.fnamemodify(self.path, ":h")
      if dir ~= "." and dir ~= "" then
        vim.fn.mkdir(dir, "p")
      end
      
      -- Move to left window (assuming chat is on the right)
      vim.cmd("wincmd h")
      
      -- Open the file in a new buffer
      vim.cmd("edit " .. vim.fn.fnameescape(self.path))
      local target_bufnr = vim.api.nvim_get_current_buf()
      
      -- Focus back to chat window
      vim.api.nvim_set_current_win(self.winid)
      
      -- Write content to the buffer
      local lines = vim.split(self.content, "\n")
      vim.api.nvim_buf_set_lines(target_bufnr, 0, -1, false, lines)
      
      -- Save the file
      vim.api.nvim_buf_call(target_bufnr, function()
        vim.cmd("write")
      end)
    end)
    
    if success then
      return {
        success = true,
        message = "Successfully wrote to " .. self.path,
      }
    else
      return {
        success = false,
        message = "Failed to write to " .. self.path .. ": " .. tostring(error_msg),
      }
    end
  elseif action_type == "reject" then
    return { success = true, message = "Rejected writing to " .. self.path }
  else
    return { success = false, message = "Unknown action type: " .. action_type }
  end
end

return M