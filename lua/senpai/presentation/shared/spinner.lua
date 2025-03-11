local M = {}
M.__index = M

---@usesage
-- local spinner1 = M:new("initialize")
-- spinner1:start()
--
-- vim.defer_fn(function()
--   spinner1:stop()
-- end, 3000)

local spinner_chars =
  { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

--- @param message string
--- @param callback? function
function M.new(message, callback)
  local self = setmetatable({}, M)
  self.spinner_index = 1
  self.is_active = false
  self.message = message
  self.notify_id = nil
  self.callback = callback
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
      if self.callback then
        self.callback(full_message)
      else
        self.notify_id = vim.notify(full_message, vim.log.levels.INFO, {
          title = "Progress",
          replace = self.notify_id,
        })
      end
    end)

    self.spinner_index = (self.spinner_index % #spinner_chars) + 1
    vim.defer_fn(update_spinner, 100)
  end

  update_spinner()
end

--- @param is_faild? boolean
function M:stop(is_faild)
  self.is_active = false
  vim.schedule(function()
    local result_message = is_faild and " FAILD!" or " finished!"
    if self.callback then
      self.callback(self.message .. result_message)
    else
      local level = is_faild and vim.log.levels.ERROR or vim.log.levels.INFO
      vim.notify(self.message .. result_message, level, {
        title = "Progress",
        replace = self.notify_id,
      })
    end
    self.notify_id = nil
  end)
end

return M
