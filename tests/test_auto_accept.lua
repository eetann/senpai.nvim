local Helpers = dofile("tests/helpers.lua")
local child = Helpers.new_child_neovim()
local eq = Helpers.expect.equality

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.lua([[M = require('senpai.presentation.chat.window')]])
    end,
    post_once = child.stop,
  },
})

-- Dummy block generator for testing
local function make_block(opts)
  opts = opts or {}
  return string.format(
    [[
    setmetatable({
      type = "%s",
      args = %s,
      get_action_buttons = function()
        return %s
      end,
      handle_action = function(action_type, user_input)
        return { success = true, message = "done", block_type = "%s" }
      end,
      block_type = "%s",
    }, { __index = M })
  ]],
    opts.type or "replace_in_file",
    opts.args or "{ path = 'foo.lua' }",
    opts.buttons or "{ { label = 'OK', approve = true, action_type = 'do' } }",
    opts.block_type or "replace_in_file",
    opts.block_type or "replace_in_file"
  )
end

T["show_action_buttons()"] = MiniTest.new_set()

T["show_action_buttons()"]["_execute_action is called when auto_approve=true"] = function()
  child.lua([[
    package.loaded["senpai.usecase.request.request_handler"] = {
      request_without_callback = function(req)
        return { exit = 0, status = 200, body = vim.json.encode({ auto_approve = true }) }
      end,
    }
    _G.called = { execute_action = false }
    local win = setmetatable({}, { __index = M })
    function win:_execute_action(button_def, block, user_input)
      _G.called.execute_action = true
    end
    function win:_render_action_buttons(buttons, block)
      _G.called.render_action_buttons = true
    end
    win.current_assistant_message_block = (]] .. make_block() .. [[)
    win:show_action_buttons()
  ]])
  local called = child.lua_get("_G.called")
  eq(called.execute_action, true)
  eq(called.render_action_buttons, nil)
end

T["show_action_buttons()"]["_render_action_buttons is called when auto_approve=false"] = function()
  child.lua([[
    package.loaded["senpai.usecase.request.request_handler"] = {
      request_without_callback = function(req)
        return { exit = 0, status = 200, body = vim.json.encode({ auto_approve = false }) }
      end,
    }
    local win = setmetatable({}, { __index = M })
    _G.called = { execute_action = false }
    function win:_execute_action(button_def, block, user_input)
      _G.called.execute_action = true
    end
    function win:_render_action_buttons(buttons, block)
      _G.called.render_action_buttons = true
    end
    win.current_assistant_message_block = (]] .. make_block() .. [[)
    win:show_action_buttons()
  ]])
  local called = child.lua_get("_G.called")
  eq(called.execute_action, false)
  eq(called.render_action_buttons, true)
end

T["show_action_buttons()"]["_render_action_buttons is called when API request fails"] = function()
  child.lua([[
    package.loaded["senpai.usecase.request.request_handler"] = {
      request_without_callback = function(req)
        return { exit = 1, status = 500, body = "" }
      end,
    }
    local win = setmetatable({}, { __index = M })
    _G.called = { execute_action = false }
    function win:_execute_action(button_def, block, user_input)
      _G.called.execute_action = true
    end
    function win:_render_action_buttons(buttons, block)
      _G.called.render_action_buttons = true
    end
    win.current_assistant_message_block = (]] .. make_block() .. [[)
    win:show_action_buttons()
  ]])
  local called = child.lua_get("_G.called")
  eq(called.execute_action, false)
  eq(called.render_action_buttons, true)
end

T["show_action_buttons()"]["_render_action_buttons is called when API response is invalid"] = function()
  child.lua([[
    package.loaded["senpai.usecase.request.request_handler"] = {
      request_without_callback = function(req)
        return { exit = 0, status = 200, body = "not_json" }
      end,
    }
    local win = setmetatable({}, { __index = M })
    _G.called = { execute_action = false }
    function win:_execute_action(button_def, block, user_input)
      _G.called.execute_action = true
    end
    function win:_render_action_buttons(buttons, block)
      _G.called.render_action_buttons = true
    end
    win.current_assistant_message_block = (]] .. make_block() .. [[)
    win:show_action_buttons()
  ]])
  local called = child.lua_get("_G.called")
  eq(called.execute_action, false)
  eq(called.render_action_buttons, true)
end

T["show_action_buttons()"]["hide_action_buttons is called when block is nil"] = function()
  child.lua([[
    local win = setmetatable({}, { __index = M })
    _G.called = { hide_action_buttons = false }
    function win:hide_action_buttons()
      _G.called.hide_action_buttons = true
    end
    win.current_assistant_message_block = nil
    win:show_action_buttons()
  ]])
  local called = child.lua_get("_G.called")
  eq(called.hide_action_buttons, true)
end

T["show_action_buttons()"]["send_text is called when get_action_buttons returns an error string"] = function()
  -- Reload M after setting senpai.usecase.send_text mock
  child.lua([[
    package.loaded["senpai.presentation.chat.window"] = nil
    package.loaded["senpai.usecase.send_text"] = {
      execute = function(self, msg)
        _G.called_send_text = true
      end,
    }
    local M = require("senpai.presentation.chat.window")
    local win = setmetatable({}, { __index = M })
    win.current_assistant_message_block = setmetatable({
      type = "replace_in_file",
      args = { path = "foo.lua" },
      get_action_buttons = function() return "error message" end,
      handle_action = function(action_type, user_input)
        return { success = true, message = "done", block_type = "replace_in_file" }
      end,
      block_type = "replace_in_file",
    }, { __index = M })
    _G.called_send_text = false
    win:show_action_buttons()
  ]])
  local called = child.lua_get("_G.called_send_text")
  eq(called, true)
end

return T
