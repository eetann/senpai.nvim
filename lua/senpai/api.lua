local ChatWindowManager = require("senpai.presentation.chat.window_manager")
local RequestHandler = require("senpai.presentation.shared.request_handler")
local utils = require("senpai.usecase.utils")

local chatWindowManager = ChatWindowManager.new()

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
        utils.set_text_at_last(vim.api.nvim_get_current_buf(), part.content)
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
  ````
  Toggle chat.
  """
--]=]
function M.toggle_chat()
  chatWindowManager:toggle_current_chat()
end

return setmetatable(M, {
  __index = function(_, k)
    return require("senpai.presentation.commit_message")[k]
      or require("senpai.presentation.history")[k]
  end,
})
