local Helpers = dofile("tests/helpers.lua")
local child = Helpers.new_child_neovim()
local expect, eq = Helpers.expect, Helpers.expect.equality

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.lua([[
-- Mock vim.diagnostic.get to return test diagnostics
_original_diagnostic_get = vim.diagnostic.get
_test_diagnostics = {}
vim.diagnostic.get = function(bufnr, opts)
    if not opts or not opts.severity then
        return _test_diagnostics
    end
    
    -- Filter by severity if specified
    local min_severity = opts.severity.min or vim.diagnostic.severity.HINT
    local filtered = {}
    for _, diag in ipairs(_test_diagnostics) do
        if diag.severity <= min_severity then
            table.insert(filtered, diag)
        end
    end
    return filtered
end
            ]])
    end,
    post_case = function()
      child.lua([[
                -- Restore original diagnostic.get
                vim.diagnostic.get = _original_diagnostic_get
                _test_diagnostics = {}
            ]])
    end,
    post_once = child.stop,
  },
})

T["handle_action with no diagnostics"] = function()
  -- Create a test file
  child.cmd("edit /tmp/test_file.js")
  local test_bufnr = child.lua_get("vim.api.nvim_get_current_buf()")

  -- Set up the block
  child.lua([[
        local ReplaceInFileBlock = require("senpai.presentation.chat.replace_in_file_block")
        test_block = ReplaceInFileBlock.new({
            winid = vim.api.nvim_get_current_win(),
            bufnr = vim.api.nvim_get_current_buf(),
            path = "/tmp/test_file.js"
        })
        test_block.origin_bufnr = ]] .. test_bufnr .. [[
        test_block.ai_bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(test_block.ai_bufnr, 0, -1, false, {"console.log('hello')"})
    ]])

  -- No diagnostics
  child.lua("_test_diagnostics = {}")

  -- Execute handle_action
  local result = child.lua_get([[test_block:handle_action("accept")]])

  eq(result.success, true)
  eq(result.message, "Successfully applied changes to /tmp/test_file.js")
end

T["handle_action with diagnostics"] = function()
  -- Create a test file
  child.cmd("edit /tmp/test_file_with_errors.js")
  local test_bufnr = child.lua_get("vim.api.nvim_get_current_buf()")

  -- Set up the block
  child.lua([[
        local ReplaceInFileBlock = require("senpai.presentation.chat.replace_in_file_block")
        test_block = ReplaceInFileBlock.new({
            winid = vim.api.nvim_get_current_win(),
            bufnr = vim.api.nvim_get_current_buf(),
            path = "/tmp/test_file_with_errors.js"
        })
        test_block.origin_bufnr = ]] .. test_bufnr .. [[
        test_block.ai_bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(test_block.ai_bufnr, 0, -1, false, {"const x = undefinedVar;"})
    ]])

  -- Set up mock diagnostics
  child.lua([[
        _test_diagnostics = {
            {
                lnum = 0,
                col = 10,
                message = "Cannot find name 'undefinedVar'",
                severity = vim.diagnostic.severity.ERROR
            }
        }
    ]])

  -- Execute handle_action
  local result = child.lua_get([[test_block:handle_action("accept")]])

  eq(result.success, true)
  -- Check that the message contains expected strings
  eq(
    result.message:find(
      "Successfully applied changes to /tmp/test_file_with_errors.js"
    ) ~= nil,
    true
  )
  eq(result.message:find("Found 1 error:") ~= nil, true)
  eq(
    result.message:find("Line 1: Cannot find name 'undefinedVar'") ~= nil,
    true
  )
end

T["handle_action with multiple diagnostics"] = function()
  -- Create a test file
  child.cmd("edit /tmp/test_file_multiple_errors.js")
  local test_bufnr = child.lua_get("vim.api.nvim_get_current_buf()")

  -- Set up the block
  child.lua([[
        local ReplaceInFileBlock = require("senpai.presentation.chat.replace_in_file_block")
        test_block = ReplaceInFileBlock.new({
            winid = vim.api.nvim_get_current_win(),
            bufnr = vim.api.nvim_get_current_buf(),
            path = "/tmp/test_file_multiple_errors.js"
        })
        test_block.origin_bufnr = ]] .. test_bufnr .. [[
        test_block.ai_bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(test_block.ai_bufnr, 0, -1, false, {
            "const x = undefinedVar1;",
            "const y = undefinedVar2;"
        })
    ]])

  -- Set up mock diagnostics
  child.lua([[
        _test_diagnostics = {
            {
                lnum = 0,
                col = 10,
                message = "Cannot find name 'undefinedVar1'",
                severity = vim.diagnostic.severity.ERROR
            },
            {
                lnum = 1,
                col = 10,
                message = "Cannot find name 'undefinedVar2'",
                severity = vim.diagnostic.severity.ERROR
            }
        }
    ]])

  -- Execute handle_action
  local result = child.lua_get([[test_block:handle_action("accept")]])

  eq(result.success, true)
  -- Check that the message contains expected strings
  eq(
    result.message:find(
      "Successfully applied changes to /tmp/test_file_multiple_errors.js"
    ) ~= nil,
    true
  )
  eq(result.message:find("Found 2 errors:") ~= nil, true)
  eq(
    result.message:find("Line 1: Cannot find name 'undefinedVar1'") ~= nil,
    true
  )
  eq(
    result.message:find("Line 2: Cannot find name 'undefinedVar2'") ~= nil,
    true
  )
end

T["handle_action ignores non-error diagnostics"] = function()
  -- Create a test file
  child.cmd("edit /tmp/test_file_warnings.js")
  local test_bufnr = child.lua_get("vim.api.nvim_get_current_buf()")

  -- Set up the block
  child.lua([[
        local ReplaceInFileBlock = require("senpai.presentation.chat.replace_in_file_block")
        test_block = ReplaceInFileBlock.new({
            winid = vim.api.nvim_get_current_win(),
            bufnr = vim.api.nvim_get_current_buf(),
            path = "/tmp/test_file_warnings.js"
        })
        test_block.origin_bufnr = ]] .. test_bufnr .. [[
        test_block.ai_bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(test_block.ai_bufnr, 0, -1, false, {"console.log('test')"})
    ]])

  -- Set up mock diagnostics with warnings
  child.lua([[
        _test_diagnostics = {
            {
                lnum = 0,
                col = 0,
                message = "Missing semicolon",
                severity = vim.diagnostic.severity.WARN
            },
            {
                lnum = 0,
                col = 0,
                message = "Use single quotes",
                severity = vim.diagnostic.severity.INFO
            }
        }
    ]])

  -- Execute handle_action
  local result = child.lua_get([[test_block:handle_action("accept")]])

  eq(result.success, true)
  -- Should not include warnings or info in the message
  eq(
    result.message,
    "Successfully applied changes to /tmp/test_file_warnings.js"
  )
end

return T

