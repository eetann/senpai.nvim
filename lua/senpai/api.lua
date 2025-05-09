local ChatWindowManager = require("senpai.presentation.chat.window_manager")
local RequestHandler = require("senpai.usecase.request.request_handler")
local utils = require("senpai.usecase.utils")
local delete_threads = require("senpai.usecase.request.delete_threads")
local regist_url_at_rag = require("senpai.usecase.regist_url_at_rag")

local M = {}

function M.hello()
  RequestHandler.request({
    method = "get",
    route = "/hello",
    callback = function(response)
      if response.exit ~= 0 then
        vim.notify("[senpai] Something is wrong.")
        return
      end
      vim.notify(response.body)
    end,
  })
end

function M.hello_stream()
  RequestHandler.streamRequest({
    method = "post",
    route = "/hello/stream",
    stream = function(_, part)
      if not part or not part.type or part.content == "" then
        return
      end
      if part.type == "0" then
        utils.set_text_at_last(
          vim.api.nvim_get_current_buf(),
          part.content --[[@as string]]
        )
      end
    end,
    callback = function(response)
      if response.exit ~= 0 then
        vim.notify("[senpai] Something is wrong.")
        return
      end
    end,
  })
end

--[=[@doc
  category = "api"
  name = "toggle_chat"
  desc = """
```lua
senpai.toggle_chat()
```
Toggle chat.
"""
--]=]
function M.toggle_chat()
  ChatWindowManager.toggle_current_chat()
end

--[=[@doc
  category = "api"
  name = "new_thread"
  desc = """
```lua
senpai.new_thread()
```
Open new chat.
"""
--]=]
function M.new_thread()
  ChatWindowManager.replace_new_thread()
end

--[=[@doc
  category = "api"
  name = "delete_thread"
  desc = """
```lua
senpai.delete_thread(thread_id)
```
Delete the specified thread.
"""

  [[args]]
  name = "thread_id"
  type = "string"
  desc = "thread_id"
--]=]
function M.delete_thread(thread_id)
  delete_threads.execute(thread_id, function()
    vim.notify("[senpai] Successfully deleted thread " .. thread_id)
  end)
end

--[=[@doc
  category = "api"
  name = "regist_url_at_rag"
  desc = """
```lua
senpai.regist_url_at_rag()
senpai.regist_url_at_rag(url)
```
Fetch URL and save to RAG.
Cache control can be configured in \|senpai.Config.rag.cache_strategy\|.
"""

  [[args]]
  name = "url"
  type = "string|nil"
  desc = "URL. If not specified, the input UI will open"

  [[args]]
  name = "no_cache"
  type = "boolean|nil"
  desc = "If set to true, no cache is used regardless of Config."
--]=]
function M.regist_url_at_rag(url, no_cache)
  regist_url_at_rag.execute(url, no_cache)
end

return setmetatable(M, {
  __index = function(_, k)
    return require("senpai.presentation.commit_message")[k]
      or require("senpai.presentation.load_thread")[k]
      or require("senpai.presentation.delete_rag_source")[k]
      or require("senpai.presentation.prompt_launcher")[k]
      or require("senpai.presentation.transfer_visual_to_chat")[k]
      or require("senpai.presentation.reload_rules")[k]
  end,
})
