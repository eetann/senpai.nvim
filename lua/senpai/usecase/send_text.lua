local Config = require("senpai.config")
local Spinner = require("senpai.presentation.shared.spinner")
local RequestHandler = require("senpai.usecase.request.request_handler")
local utils = require("senpai.usecase.utils")
local UserMessage = require("senpai.usecase.message.user")
local AssistantMessage = require("senpai.usecase.message.assistant")
local ErrorMessage = require("senpai.usecase.message.error")
local ToolResultMessage = require("senpai.usecase.message.tool_result")
local ToolCallMessage = require("senpai.usecase.message.tool_call")
local IChatWindow = require("senpai.domain.i_chat_window")

local M = {}
M.__index = M

---@param winid integer
---@param bufnr integer
---@param links string[]
local function keep_file_attachment(winid, bufnr, links)
  local text = table.concat(links, " ")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { text, "" })
  vim.api.nvim_buf_set_extmark(
    bufnr,
    vim.api.nvim_create_namespace("sepnai-chat"),
    0,
    0,
    {
      conceal_lines = "",
    }
  )
  vim.api.nvim_win_set_cursor(winid, { 2, 1 })
end

---send chat to LLM
---@param chat senpai.IChatWindow
---@param user_input? string
function M.execute(chat, user_input)
  if chat.is_sending then
    return
  end
  --@type string[]
  local lines
  if type(user_input) == "string" then
    lines = vim.split(user_input, "\n")
  else
    lines = vim.api.nvim_buf_get_lines(chat.input_area.bufnr, 0, -1, false)
    user_input = table.concat(lines, "\n")
  end
  if user_input == "" then
    return
  end

  chat.is_sending = true
  UserMessage.render_from_request(chat, lines)
  local assistant = AssistantMessage.new(chat)

  local spinner = Spinner.new(
    "Senpai thinking",
    -- update
    function(message)
      utils.set_winbar(chat.input_area.winid, message)
    end,
    -- finish
    function(message)
      chat.is_sending = false
      utils.set_winbar(chat.input_area.winid, message)
      vim.defer_fn(function()
        utils.set_winbar(chat.input_area.winid, IChatWindow.input_winbar_text)
      end, 2000)
    end
  )
  spinner:start()
  local body = {
    thread_id = chat.thread_id,
    provider = chat.provider,
    text = user_input,
    system_prompt = chat.system_prompt,
    auto_rag = Config.rag.mode == "auto",
  }
  local filelinks = utils.parse_filelinks(user_input)
  if #filelinks.headers > 0 then
    body.code_block_headers = filelinks.headers
    if Config.chat.input_area.keep_file_attachment then
      keep_file_attachment(
        chat.input_area.winid,
        chat.input_area.bufnr,
        filelinks.links
      )
    end
  end
  chat.job = RequestHandler.streamRequest({
    method = "post",
    route = "/chat",
    body = body,
    stream = function(_, part)
      if not part or not part.type or part.content == "" then
        return
      end
      local winid = chat.log_area.winid
      local last_buffer_line = vim.fn.line("$", winid)
      if part.type == "0" then
        assistant:render_from_response(part)
      elseif part.type == "3" then
        ErrorMessage.render_from_response(chat, part)
      elseif part.type == "9" then
        ToolCallMessage.render_from_response(chat, part)
      elseif part.type == "a" then
        ToolResultMessage.render_from_response(chat, part)
      end
      if last_buffer_line <= vim.fn.line(".", winid) then
        utils.scroll_when_invisible(chat)
      end
    end,
    callback = function()
      spinner:stop()
    end,
  })
end

return M
