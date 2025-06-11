local Helpers = dofile("tests/helpers.lua")
local child = Helpers.new_child_neovim()
local expect, eq = Helpers.expect, Helpers.expect.equality

local sleep = function(ms)
  Helpers.sleep(ms, child)
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.lua([[M=require("senpai.usecase.message.assistant")]])
    end,
    post_once = child.stop,
  },
})

T["<search_files>"] = MiniTest.new_set()

T["tool_result: SearchFiles block is rendered"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_search_files" } }
  )
  child.lua([[chat:show()]])
  local bufnr = child.lua_get([[chat.log_area.bufnr]])

  local tool_result_part = {
    toolCallId = "SearchFiles-2025-04-20",
    toolName = "SearchFiles",
    result = {
      path = "src",
      regex = "function.*test",
      filePattern = "*.ts",
    },
  }
  child.lua(
    'require("senpai.usecase.message.tool_result").render_from_memory(chat, ...)',
    { tool_result_part }
  )

  -- Add a small delay to ensure buffer is updated
  sleep(10)
  
  local lines = child.get_lines(bufnr)
  local found = false
  for i = #lines - 10, #lines do
    if lines[i] and lines[i]:find("> %[!NOTE%] SearchFiles") then
      found = true
      eq(lines[i], "> [!NOTE] SearchFiles")
      eq(lines[i+1], "> Senpai search for `function.*test` in directory `src`:")
      eq(lines[i+2], "> File pattern: `*.ts`")
      break
    end
  end
  assert(found, "Could not find SearchFiles block in buffer")
end

T["tool_result: SearchFiles success message is rendered"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_search_files" } }
  )
  child.lua([[chat:show()]])
  local bufnr = child.lua_get([[chat.log_area.bufnr]])

  local tool_result_part = {
    toolName = "SearchFiles",
    result = {
      path = "src",
      regex = "test",
      filePattern = "*.lua",
    },
  }
  child.lua(
    'require("senpai.usecase.message.tool_result").render_from_memory(chat, ...)',
    { tool_result_part }
  )

  local action_result_part = { 
    role = "user", 
    content = "[search_files] Result:\n\nSearch completed:\nsrc/test.lua:10: function test()\n\nTotal matches: 1" 
  }

  child.lua(
    'require("senpai.usecase.message.user").render_from_memory(chat, ...)',
    { action_result_part }
  )

  -- Check that the action result is rendered as a block quote
  local lines = child.get_lines(bufnr)

  -- The success message will have a different position since we have a SearchFiles block first
  local api_request_found = false
  for i = #lines - 15, #lines do
    if lines[i] and lines[i]:find("> %[search_files%] Result:") then
      api_request_found = true
      eq(lines[i-1], "> [!NOTE] API Request")
      eq(lines[i], "> [search_files] Result:")
      eq(lines[i+1], "> ")
      eq(lines[i+2], "> ")
      eq(lines[i+3], "> Search completed:")
      eq(lines[i+4], "> src/test.lua:10: function test()")
      eq(lines[i+5], "> ")
      eq(lines[i+6], "> Total matches: 1")
      break
    end
  end
  assert(api_request_found, "Could not find API Request block in buffer")
end

T["tool_result: SearchFiles error message is rendered"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_search_files" } }
  )
  child.lua([[chat:show()]])
  local bufnr = child.lua_get([[chat.log_area.bufnr]])

  local tool_result_part = {
    toolName = "SearchFiles",
    result = {
      path = "non-existent-dir",
      regex = "test",
      filePattern = "*",
    },
  }
  child.lua(
    'require("senpai.usecase.message.tool_result").render_from_memory(chat, ...)',
    { tool_result_part }
  )

  local action_result_part = {
    role = "user",
    content = "[search_files] Result:\n\nError: directory not found: non-existent-dir",
  }

  child.lua(
    'require("senpai.usecase.message.user").render_from_memory(chat, ...)',
    { action_result_part }
  )

  local lines = child.get_lines(bufnr)
  
  -- Find the error message block
  local error_found = false
  for i = #lines - 15, #lines do
    if lines[i] and lines[i]:find("> %[search_files%] Result:") then
      error_found = true
      eq(lines[i-1], "> [!NOTE] API Request")
      eq(lines[i], "> [search_files] Result:")
      eq(lines[i+1], "> ")
      eq(lines[i+2], "> ")
      eq(lines[i+3], "> Error: directory not found: non-existent-dir")
      break
    end
  end
  assert(error_found, "Could not find error message block in buffer")
end

T["tool_result: SearchFiles with default file pattern"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_search_files" } }
  )
  child.lua([[chat:show()]])
  local bufnr = child.lua_get([[chat.log_area.bufnr]])

  local tool_result_part = {
    toolCallId = "SearchFiles-2025-04-20",
    toolName = "SearchFiles",
    result = {
      path = ".",
      regex = "TODO",
      filePattern = "*", -- Default value
    },
  }
  child.lua(
    'require("senpai.usecase.message.tool_result").render_from_memory(chat, ...)',
    { tool_result_part }
  )

  -- Add a small delay to ensure buffer is updated
  sleep(10)
  
  local lines = child.get_lines(bufnr)
  local found = false
  for i = #lines - 10, #lines do
    if lines[i] and lines[i]:find("> %[!NOTE%] SearchFiles") then
      found = true
      eq(lines[i], "> [!NOTE] SearchFiles")
      eq(lines[i+1], "> Senpai search for `TODO` in directory `.`:")
      eq(lines[i+2], "> File pattern: `*`")
      break
    end
  end
  assert(found, "Could not find SearchFiles block in buffer")
end

return T