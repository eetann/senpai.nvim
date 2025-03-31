local post_rag_index = require("senpai.usecase.request.post_rag_index")
local Spinner = require("senpai.presentation.shared.spinner")
local M = {}

local function process_rag_registration(use_cache, url)
  local spinner = Spinner.new("[senpai] Registering")
  spinner:start()
  post_rag_index.execute({
    type = "url",
    url = url,
  }, function(response)
    if response.exit ~= 0 or response.status ~= 200 then
      vim.notify(
        "[senpai] Registration with RAG failed: " .. url,
        vim.log.levels.WARN
      )
      return
    end
    local ok, message = pcall(vim.json.decode, response.body)
    if not ok or type(message) ~= "string" then
      message = ""
    end
    if message ~= "" then
      vim.notify(
        "[senpai] Registration with RAG failed: " .. url .. "\n" .. message,
        vim.log.levels.WARN
      )
      return
    end
    vim.notify("[senpai] Registered with RAG: " .. url)
  end, function()
    spinner:stop()
  end)
end

---@param use_cache boolean
---@param url? string
function M.execute(use_cache, url)
  if not url and url ~= "" then
    process_rag_registration(use_cache, url)
  end
  vim.ui.input({
    prompt = "URL",
  }, function(text)
    if not text or text == "" then
      return
    end
    process_rag_registration(use_cache, text)
  end)
end

return M
