local IBlock = require("senpai.domain.i_block")
local n = require("nui-components")
local Columns = require("nui-components.columns")
local Gap = require("nui-components.gap")
local utils = require("senpai.usecase.utils")

---@class senpai.AskFollowupQuestionBlock: senpai.IBlock
---@field block_type "ask_followup_question"
---@field suggestion string
local M = {}
M.__index = M
setmetatable(M, { __index = IBlock })

---@param opts {row:integer|nil, winid:integer, bufnr:integer, suggestion:string}
---@return senpai.AskFollowupQuestionBlock
function M.new(opts)
  local self = setmetatable({}, M)
  self.block_type = "ask_followup_question"
  local row = opts.row or vim.api.nvim_buf_line_count(opts.bufnr)
  self.row = row
  self.winid = opts.winid
  self.bufnr = opts.bufnr
  self.suggestion = opts.suggestion

  self:setup()
  return self
end

---@return boolean
function M:has_ui()
  return true
end

-- without action_buttons
-- function M:get_action_buttons()
--   return {}
-- end

function M:setup_body()
  -- TODO: questionの描画は別のところでやる
  -- Set question text in buffer
  local lines = {
    "Question:",
    self.question,
  }
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, lines)

  self.body = Columns({
    flex = 1,
    children = {
      n.paragraph("╰"),
      Gap({ flex = 1 }, { zindex = 49 }), -- left flex
      n.button({
        label = " 󰒊 ",
        align = "center",
        on_press = function()
          local ChatWindowManager =
            require("senpai.presentation.chat.window_manager")
          local chat = ChatWindowManager:get_current_chat() --[[@as senpai.IChatWindow]]
          require("senpai.usecase.send_text").execute(
            chat,
            self.suggestion,
            nil
          )
        end,
      }),
      Gap({ size = 1 }, { zindex = 49 }),
      n.button({
        label = "  ",
        align = "center",
        on_press = function()
          local ChatWindowManager =
            require("senpai.presentation.chat.window_manager")
          local chat = ChatWindowManager:get_current_chat() --[[@as senpai.IChatWindow]]
          utils.set_text_at_last(chat.input_area.bufnr, self.suggestion)
        end,
      }),
    },
  }, {
    zindex = 50,
  })
end

return M
