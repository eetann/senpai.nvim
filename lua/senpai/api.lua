local ChatBufferManager = require("senpai.presentation.chat_buffer_manager")
local RequestHandler = require("senpai.presentation.shared.request_handler")
local WriteChat = require("senpai.presentation.write_chat")

local chatBufferManager = ChatBufferManager.new()

local M = {}

function M.hello()
  RequestHandler.request({
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
    route = "/helloStream",
    stream = function(_, part)
      if not part or not part.type or part.content == "" then
        return
      end
      if part.type == "0" then
        WriteChat.set_text_at_last(vim.api.nvim_get_current_buf(), part.content)
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
  name = "senpai.toggle_chat()"
  desc = "Toggle chat."
--]=]
function M.toggle_chat()
  chatBufferManager:toggle_current_chat()
end

return setmetatable(M, {
  __index = function(_, k)
    return require("senpai.presentation.commit_message")[k]
      or require("senpai.presentation.summarize")[k]
  end,
})
