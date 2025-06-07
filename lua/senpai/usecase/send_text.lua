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
---@param user_input? string User input text (wrapped with task/user_feedback tags)
---@param other_input? string Other input text (tool results, etc., sent as-is)
function M.execute(chat, user_input, other_input)
  if chat.is_sending then
    return
  end

  local message_parts = {}
  local original_text = ""

  -- Handle user input
  if user_input and user_input ~= "" then
    if chat.is_first_message then
      table.insert(message_parts, "<task>" .. user_input .. "</task>")
      chat.is_first_message = false
    else
      table.insert(
        message_parts,
        "<user_feedback>" .. user_input .. "</user_feedback>"
      )
    end
    original_text = user_input
  end

  -- Handle other input (tool results, etc.)
  if other_input and other_input ~= "" then
    table.insert(message_parts, other_input)
    if original_text == "" then
      original_text = other_input
    end
  end

  -- If both inputs are empty, try to get from input area
  if #message_parts == 0 then
    local lines =
      vim.api.nvim_buf_get_lines(chat.input_area.bufnr, 0, -1, false)
    local text = table.concat(lines, "\n")
    if text == "" then
      return
    end
    if chat.is_first_message then
      table.insert(message_parts, "<task>" .. text .. "</task>")
      chat.is_first_message = false
    else
      table.insert(
        message_parts,
        "<user_feedback>" .. text .. "</user_feedback>"
      )
    end
    original_text = text
  end

  local final_text = table.concat(message_parts, "\n\n")

  chat.is_sending = true

  -- Render user message display (use original user input for display)
  local display_lines
  if user_input and user_input ~= "" then
    display_lines = vim.split(user_input, "\n")
  else
    display_lines = vim.split(original_text, "\n")
  end
  UserMessage.render_from_request(chat, display_lines)

  -- Reset current assistant message block for new message
  chat:on_assistant_message_start()

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
    text = final_text,
    system_prompt = chat.system_prompt,
    auto_rag = Config.rag.mode == "auto",
  }
  local filelinks = utils.parse_filelinks(original_text)
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
      -- Show action buttons after AI message is complete
      chat:show_action_buttons()
    end,
  })
end

return M
