local ChatWindowManager = require("senpai.presentation.chat.window_manager")
local RequestHandler = require("senpai.usecase.request.request_handler")
local utils = require("senpai.usecase.utils")
local delete_threads = require("senpai.usecase.request.delete_threads")

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

return setmetatable(M, {
  __index = function(_, k)
    return require("senpai.presentation.commit_message")[k]
      or require("senpai.presentation.load_thread")[k]
  end,
})
