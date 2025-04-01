local M = {}

---@param launcher senpai.Config.PromptLauncher.launcher
---@return senpai.Config.PromptLauncher.resolved_launcher
function M.execute(launcher)
  ---@type senpai.Config.PromptLauncher.resolved_launcher
  local result = {}
  if launcher.provider then
    result.provider = launcher.provider
  end
  if launcher.thread_id then
    result.thread_id = launcher.thread_id
  end

  if type(launcher.system) == "function" then
    result.system_prompt = launcher.system()
  elseif type(launcher.system) == "string" then
    result.system_prompt = launcher.system --[[@as string]]
  end

  if type(launcher.user) == "function" then
    result.user_prompt = launcher.user()
  elseif type(launcher.user) == "string" then
    result.user_prompt = launcher.user --[[@as string]]
  end
  return result
end

return M
