local Config = require("senpai.config")
local Split = require("nui.split")
local utils = require("senpai.usecase.utils")
local set_messages = require("senpai.usecase.set_messages")
local Keymaps = require("senpai.presentation.chat.keymaps")
local IChatWindow = require("senpai.domain.i_chat_window")
local StickyPopupManager =
  require("senpai.presentation.chat.sticky_popup_manager")
local n = require("nui-components")
local Gap = require("nui-components.gap")
local Columns = require("nui-components.columns")
local Rows = require("nui-components.rows")
local send_text = require("senpai.usecase.send_text")

local function create_winbar_text(text)
  return "%#Nomal#%=" .. text .. "%="
end

local win_options = {
  colorcolumn = "",
  number = false,
  relativenumber = false,
  signcolumn = "yes",
  spell = false,
  statuscolumn = "",
  wrap = true,
  fillchars = "eob: ",
  -- listchars = "eol: ",
}

---@class senpai.ChatWindow: senpai.IChatWindow
---@field is_new boolean
---@field current_assistant_message_block any|nil The block from the current assistant message
local M = {}
M.__index = M

-- TODO: nuiのlayoutへ置き換える

---@param args senpai.ChatWindowNewArgs
---@return senpai.ChatWindow|nil
function M.new(args)
  args = args or {}
  local self = setmetatable({}, M)
  local provider = Config.get_provider(args.provider)
  if not provider then
    return
  end
  self.provider = provider

  if args.thread_id then
    self.thread_id = args.thread_id
    self.is_new = args.thread_id:find("^test_render.*") and true or false
  else
    self.thread_id = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
      .. "-"
      .. os.date("%Y%m%d%H%M%S")
    self.is_new = true
  end

  self.system_prompt = ""
  if args.system_prompt then
    self.system_prompt = args.system_prompt
  elseif Config.chat.system_prompt then
    self.system_prompt = Config.chat.system_prompt
  end

  self.is_sending = false
  self.is_first_message = true
  return self
end

---@param area NuiSplit
---@param keymaps table<string, senpai.Config.chat.keymap>
function M:apply_keymaps(area, keymaps)
  for key, value in pairs(keymaps) do
    if type(value.mode) == "string" then
      area:map(value.mode --[[@as string]], key, value[1])
    else
      for _, mode in
        pairs(value.mode --[=[@as string[]]=])
      do
        area:map(mode, key, value[1])
      end
    end
  end
end

--- @param keymaps table<string, senpai.Config.chat.keymap>
function M:create_log_area(keymaps)
  self.log_area = Split({
    relative = "editor",
    position = "right",
    size = Config.chat.common.width or 80,
    win_options = vim.tbl_deep_extend("force", win_options, {
      winbar = create_winbar_text("Conversations with Senpai"),
      conceallevel = 3,
    }),
    buf_options = {
      filetype = "senpai_chat_log",
    },
  })
  self:apply_keymaps(self.log_area, keymaps)

  -- Add custom keymap for toggling action result fold
  local action_result_renderer =
    require("senpai.usecase.message.action_result_renderer")
  vim.keymap.set("n", "<CR>", function()
    local row = vim.fn.line(".")
    local quote_range =
      action_result_renderer.get_block_quote_range(row, self.log_area.bufnr)
    if quote_range then
      action_result_renderer.toggle_action_result_fold(
        self.log_area.bufnr,
        quote_range
      )
    end
  end, {
    buffer = self.log_area.bufnr,
    desc = "Toggle action result fold",
  })
end

---@param keymaps table<string, senpai.Config.chat.keymap>
function M:create_input_area(keymaps)
  self.input_area = Split({
    relative = "win",
    position = "bottom",
    size = Config.chat.input_area.height or "25%",
    win_options = vim.tbl_deep_extend("force", win_options, {
      winbar = create_winbar_text(IChatWindow.input_winbar_text),
    }),
    buf_options = {
      filetype = "senpai_chat_input",
    },
  })
  self:apply_keymaps(self.input_area, keymaps)
end

function M:setup_log_area(winid)
  if winid then
    self.log_area.winid = winid
    vim.api.nvim_win_set_buf(self.log_area.winid, self.log_area.bufnr)
    --- @diagnostic disable-next-line: invisible
    for name, value in pairs(self.log_area._.win_options) do
      vim.api.nvim_set_option_value(
        name,
        value,
        { scope = "local", win = self.log_area.winid }
      )
    end
    vim.api.nvim_set_current_win(self.log_area.winid)
  end
  self.sticky_popup_manager =
    StickyPopupManager.new(self.log_area.winid, self.log_area.bufnr)
end

function M:display_chat_info()
  utils.set_text_at_last(
    self.log_area.bufnr,
    string.format(
      [[
---
name: "%s"
model_id: "%s"
thread_id: "%s"
---
]],
      self.provider.name,
      self.provider.model_id,
      self.thread_id
    )
  )
end

---@param winid? number
function M:show(winid)
  local resolved_keymaps
  if
    not self.log_area or not vim.api.nvim_buf_is_loaded(self.log_area.bufnr)
  then
    resolved_keymaps = Keymaps.new(self)
    self:create_log_area(resolved_keymaps.log_area)
    if winid then
      self:setup_log_area(winid)
    end
    self.log_area:mount()
    self.sticky_popup_manager =
      StickyPopupManager.new(self.log_area.winid, self.log_area.bufnr)
    self:display_chat_info()
    if not self.is_new then
      set_messages.execute(self)
    end
  else
    self.log_area:show()
    self.sticky_popup_manager:remount(self.log_area.winid)
  end

  if
    not self.input_area or not vim.api.nvim_buf_is_loaded(self.input_area.bufnr)
  then
    if not resolved_keymaps then
      resolved_keymaps = Keymaps.new(self)
    end
    self:create_input_area(resolved_keymaps.input_area)
    self.input_area:mount()
  else
    self.input_area:update_layout({
      relative = "win",
      position = "bottom",
    })
    self.input_area:show()
  end

  vim.api.nvim_set_current_buf(self.input_area.bufnr)
  vim.cmd("normal G$")
  self:show_action_buttons()
end

function M:hide()
  self.sticky_popup_manager:close_all_popup()
  self:hide_action_buttons()
  self.log_area:hide()
  self.input_area:hide()
end

function M:destroy()
  self.log_area:unmount()
  self.input_area:unmount()
end

function M:is_hidden()
  local winid = self.log_area.winid
  if winid and vim.api.nvim_win_is_valid(winid) then
    return false
  end
  return true
end

function M:toggle()
  if self:is_hidden() then
    self:show()
  else
    self:hide()
  end
end

function M:toggle_input()
  local winid = self.input_area.winid
  self:hide_action_buttons()
  if
    not self.input_area or not vim.api.nvim_buf_is_loaded(self.input_area.bufnr)
  then
    local resolved_keymaps = Keymaps.new(self)
    self:create_input_area(resolved_keymaps.input_area)
    self.input_area:mount()
  elseif winid and vim.api.nvim_win_is_valid(winid) then
    self.input_area:hide()
  else
    self.input_area:show()
  end
  self:show_action_buttons()
end

---Reset current assistant message block when a new AI message starts
function M:on_assistant_message_start()
  self.current_assistant_message_block = nil
end

---@param type "replace_in_file"|"execute_command"
---@param args any
---@param row? integer
function M:add_block(type, args, row)
  if not self.sticky_popup_manager then
    self.sticky_popup_manager =
      StickyPopupManager.new(self.log_area.winid, self.log_area.bufnr)
  end
  local block = self.sticky_popup_manager:add_block(type, args, row)
  -- Record this as the current assistant message block
  self.current_assistant_message_block = block
  return block
end

---Show action buttons for the last tool in AI message
function M:show_action_buttons()
  -- Only show buttons for the current assistant message's block
  local block = self.current_assistant_message_block
  if not block or not block.get_action_buttons then
    -- Hide action buttons if there's no block with action buttons
    self:hide_action_buttons()
    return
  end

  local buttons = block:get_action_buttons()
  -- Send to AI if error
  if type(buttons) == "string" then
    -- buttons as error
    send_text.execute(self, nil, buttons)
    return
  end
  -- Check auto approval
  local RequestHandler = require("senpai.usecase.request.request_handler")

  -- Prepare request based on block type
  local auto_request = {
    tool_type = block.type,
  }

  if block.type == "replace_in_file" then
    auto_request.path = block.args.path
  elseif block.type == "execute_command" then
    auto_request.command = block.args.command
  end

  -- Use RequestHandler for internal API call
  local response = RequestHandler.request_without_callback({
    method = "post",
    route = "/agent/auto",
    body = auto_request,
  })

  if response.exit ~= 0 or response.status ~= 200 then
    -- API call failed, show buttons
    self:_render_action_buttons(buttons, block)
    return
  end

  local ok, body = pcall(vim.json.decode, response.body)
  if not ok or type(body) ~= "table" then
    -- Failed to parse response, show buttons
    self:_render_action_buttons(buttons, block)
    return
  end

  if body.auto_approve then
    -- Auto approve - execute the first enabled action
    for _, button_def in ipairs(buttons) do
      if button_def.enabled ~= false then
        self:_execute_action(button_def, block, "")
        return
      end
    end
  else
    -- Manual approval - show buttons
    self:_render_action_buttons(buttons, block)
  end
end

---Execute action with given user input
---@param button_def table
---@param block any
---@param user_input string
function M:_execute_action(button_def, block, user_input)
  -- Handle the action (without user_input, handle_action only returns tool result)
  local result = block:handle_action(button_def.action_type)

  if result.success then
    -- Build tool result message
    local tool_message = "["
      .. block.block_type
      .. "] Result:\n\n"
      .. result.message

    -- Send user input and tool result together
    local user_part = (user_input and user_input ~= "") and user_input or nil
    send_text.execute(self, user_part, tool_message)

    -- Hide action buttons after use
    self:hide_action_buttons()
  else
    vim.notify("Action failed: " .. result.message, vim.log.levels.ERROR)
  end
end

---Render action buttons
---@param buttons table
---@param block any
function M:_render_action_buttons(buttons, block)
  -- Build button components
  local button_components = {}
  for _, button_def in ipairs(buttons) do
    if button_def.enabled ~= false then
      table.insert(
        button_components,
        n.button({
          label = button_def.label,
          flex = 1,
          align = "left",
          on_press = function()
            -- Get user input from input area
            local user_input = ""
            if self.input_area and self.input_area.bufnr then
              local lines =
                vim.api.nvim_buf_get_lines(self.input_area.bufnr, 0, -1, false)
              user_input = table.concat(lines, "\n")
              -- Clear input area after getting text
              vim.api.nvim_buf_set_lines(
                self.input_area.bufnr,
                0,
                -1,
                false,
                {}
              )
            end

            -- Execute the action
            self:_execute_action(button_def, block, user_input)
          end,
        })
      )
    end
  end

  if #button_components == 0 then
    return
  end

  -- Create the action button renderer
  self.action_buttons_renderer = n.create_renderer({
    bufnr = self.log_area.bufnr,
    relative = {
      type = "win",
      winid = self.log_area.winid,
    },
    position = {
      row = vim.api.nvim_win_get_height(self.log_area.winid)
        - 1
        - #button_components,
      col = 0,
    },
    -- width = vim.api.nvim_win_get_width(self.log_area.winid),
    height = #button_components,
  })

  self.action_buttons_renderer:render(Rows({
    flex = 1,
    children = button_components,
  }))
end

---Hide action buttons
function M:hide_action_buttons()
  if self.action_buttons_renderer then
    self.action_buttons_renderer:close()
    self.action_buttons_renderer = nil
  end
end

return M
