local IBlock = require("senpai.domain.i_block")
local utils = require("senpai.usecase.utils")

---@class senpai.SearchFilesBlock: senpai.IBlock
---@field block_type "search_files"
---@field path string
---@field regex string
---@field filePattern string
local M = {}
M.__index = M
setmetatable(M, { __index = IBlock })

---@param opts { winid:integer, bufnr:integer, path:string, regex:string, filePattern:string, row:integer|nil }
---@return senpai.SearchFilesBlock
function M.new(opts)
  local self = setmetatable({}, M)
  self.block_type = "search_files"
  self.path = opts.path
  self.regex = opts.regex
  self.filePattern = opts.filePattern
  local row = opts.row or vim.api.nvim_buf_line_count(opts.bufnr)
  self.row = row
  self.winid = opts.winid
  self.bufnr = opts.bufnr

  -- UI-less block, no need to setup or mount
  utils.replace_lines_at_last(self.bufnr, {
    "",
    "> [!NOTE] SearchFiles",
    "> Senpai search for `"
      .. self.regex
      .. "` in directory `"
      .. self.path
      .. "`:",
    "> File pattern: `" .. self.filePattern .. "`",
    "",
  })

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
    -- Make API request to search files
    local request_handler = require("senpai.usecase.request.request_handler")
    local response = request_handler.request_without_callback({
      method = "post",
      route = "/agent/search_files",
      body = {
        path = self.path,
        regex = self.regex,
        filePattern = self.filePattern,
      },
    })

    if response.exit ~= 0 or response.status ~= 200 then
      return {
        success = false,
        message = "Search failed: " .. (response.body or "Unknown error"),
      }
    end

    local ok, body = pcall(vim.json.decode, response.body)
    if not ok or type(body) ~= "table" then
      return {
        success = false,
        message = "Search failed: Invalid response format",
      }
    end

    if body.error then
      return {
        success = false,
        message = "Search failed: " .. body.error,
      }
    end

    local message = "Search completed:\n" .. (body.results or "")

    return { success = true, message = message }
  elseif action_type == "reject" then
    local message = "Rejected search in "
      .. self.path
      .. " for pattern: "
      .. self.regex
    return { success = false, message = message }
  else
    return { success = false, message = "Unknown action type: " .. action_type }
  end
end

return M
