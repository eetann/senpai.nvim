local Config = require("senpai.config")
local post_rag_index = require("senpai.usecase.request.rag.post_rag_index")
local Spinner = require("senpai.presentation.shared.spinner")
local check_has_cache = require("senpai.usecase.request.rag.check_has_cache")
local YesnoPopup = require("senpai.usecase.popup.yesno_popup")

local M = {}

---@param url string
local function post(url)
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

---@param cache_strategy senpai.Config.rag.cache_strategy
---@param url string
local function process_rag_registration(cache_strategy, url)
  if cache_strategy == "no_cache" then
    post(url)
    return
  end
  local has_cache = check_has_cache.execute(url)
  if has_cache then
    if cache_strategy == "use_cache" then
      return
    end
    YesnoPopup.new({ "There's a cache. Do you want to use it?" }):execute({
      yes = function() end,
      cancel = function() end,
      no = function()
        post(url)
      end,
    })
    return
  end
  post(url)
end

---@param url? string
---@param no_cache? boolean
function M.execute(url, no_cache)
  ---@type senpai.Config.rag.cache_strategy
  local cache_strategy = "ask"
  if no_cache then
    cache_strategy = "no_cache"
  else
    cache_strategy = Config.rag.cache_strategy or "ask"
  end
  if url and url ~= "" then
    process_rag_registration(cache_strategy, url)
    return
  end
  vim.ui.input({
    prompt = "URL",
  }, function(text)
    if not text or text == "" then
      return
    end
    process_rag_registration(cache_strategy, text)
  end)
end

return M
