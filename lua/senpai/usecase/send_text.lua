local Spinner = require("senpai.presentation.shared.spinner")
local RequestHandler = require("senpai.presentation.shared.request_handler")
local utils = require("senpai.usecase.utils")

local M = {}
M.__index = M

---send chat to LLM
---@param chat senpai.ChatWindow
function M:execute(chat)
  local user_input = M.process_user_input(chat)

  local spinner = Spinner.new(
    "Senpai thinking",
    -- update
    function(message)
      utils.set_winbar(chat.chat_input.winid, message)
    end,
    -- finish
    function(message)
      utils.set_winbar(chat.chat_input.winid, message)
      vim.defer_fn(function()
        utils.set_winbar(chat.chat_input.winid, "Ask Senpai")
      end, 2000)
    end
  )
  spinner:start()
  RequestHandler.streamRequest({
    route = "/chat",
    body = {
      thread_id = chat.thread_id,
      provider = chat.provider,
      provider_config = chat.provider_config,
      system_prompt = chat.system_prompt,
      text = user_input,
    },
    stream = function(_, part)
      if not part or not part.type or part.content == "" then
        return
      end
      if part.type == "0" then
        utils.set_text_at_last(chat.chat_log.bufnr, part.content)
      end
    end,
    callback = function()
      spinner:stop()
    end,
  })
end

---@param chat senpai.ChatWindow
---@return string user_input
function M.process_user_input(chat)
  local start_row = vim.fn.line("$", chat.chat_log.winid)

  local lines = vim.api.nvim_buf_get_lines(chat.chat_input.bufnr, 0, -1, false)
  vim.api.nvim_buf_set_lines(chat.chat_input.bufnr, 0, -1, false, {})
  local user_input = table.concat(lines, "\n")
  local render_text = string.format(
    [[

<SenpaiUserInput>

%s

</SenpaiUserInput>
]],
    user_input
  )

  -- user input
  utils.set_text_at_last(chat.chat_log.bufnr, render_text)
  M.create_borders(chat.chat_log.bufnr, start_row, #lines)
  return user_input
end

function M.create_borders(bufnr, start_row, user_input_row_length)
  local namespace = vim.api.nvim_create_namespace("sepnai-chat")
  local start_index = start_row - 1 -- 0 based

  local startTagIndex = start_index + 1
  local endTagIndex = start_index + 2 + user_input_row_length + 2
  -- NOTE: I want to use only virt_text to put indent,
  -- but it shifts during `set wrap`, so I also use sign_text.

  -- border top
  vim.api.nvim_buf_set_extmark(
    bufnr,
    namespace,
    startTagIndex, -- 0-based
    0,
    {
      sign_text = "╭",
      sign_hl_group = "NonText",
      virt_text = { { string.rep("─", 150), "NonText" } },
      virt_text_pos = "overlay",
      virt_text_hide = true,
    }
  )

  -- border left
  for i = startTagIndex + 1, endTagIndex - 1 do
    vim.api.nvim_buf_set_extmark(
      bufnr,
      namespace,
      i, -- 0-based
      0,
      {
        sign_text = "│",
        sign_hl_group = "NonText",
      }
    )
  end

  -- border bottom
  vim.api.nvim_buf_set_extmark(
    bufnr,
    namespace,
    endTagIndex, -- 0-based
    0,
    {
      sign_text = "╰",
      sign_hl_group = "NonText",
      virt_text = { { string.rep("─", 150), "NonText" } },
      virt_text_pos = "overlay",
      virt_text_hide = true,
    }
  )
end

return M
