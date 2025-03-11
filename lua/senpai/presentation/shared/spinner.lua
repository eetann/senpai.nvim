local M = {}
M.__index = M

local spinner_chars =
  { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

---@param message string
function M.new(message)
  local self = setmetatable({}, M)
  self.spinner_index = 1
  self.is_active = false
  self.message = message
  self.notify_id = nil
  return self
end

function M:start()
  if self.is_active then
    return
  end

  self.is_active = true

  local function update_spinner()
    if not self.is_active then
      return
    end

    vim.schedule(function()
      local full_message = spinner_chars[self.spinner_index]
      if self.message then
        full_message = full_message .. " " .. self.message
      end
      self.notify_id = vim.notify(full_message, vim.log.levels.INFO, {
        title = "Progress",
        replace = self.notify_id,
      })
    end)

    self.spinner_index = (self.spinner_index % #spinner_chars) + 1
    vim.defer_fn(update_spinner, 100)
  end

  update_spinner()
end

---@param is_faild? boolean
function M:stop(is_faild)
  self.is_active = false
  vim.schedule(function()
    if is_faild then
      vim.notify(self.message .. " FAILD!", vim.log.levels.ERROR, {
        title = "Progress",
        replace = self.notify_id,
      })
    else
      vim.notify(self.message .. " finished!", vim.log.levels.INFO, {
        title = "Progress",
        replace = self.notify_id,
      })
    end
    self.notify_id = nil
  end)
end

-- usesage
-- local spinner1 = M:new("処理1中...")
-- spinner1:start()
--
-- vim.defer_fn(function()
--   spinner1:stop()
-- end, 3000)

return M
