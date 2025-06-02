local Helpers = dofile("tests/helpers.lua")
local child = Helpers.new_child_neovim()
local expect, eq = Helpers.expect, Helpers.expect.equality

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.setup()
            child.lua([[tool_call = require("senpai.usecase.message.tool_call")]])
            child.lua([[tool_result = require("senpai.usecase.message.tool_result")]])
        end,
        post_once = child.stop,
    },
})

T["tool_call: ReplaceInFile diff block is rendered"] = function()
    child.lua(
        [[chat=require("senpai.presentation.chat.window").new(...)]],
        { { thread_id = "test_render_message_replace_in_file" } }
    )
    child.lua([[chat:show()]])
    local bufnr = child.lua_get([[chat.log_area.bufnr]])

    local tool_call_part = {
        toolName = "ReplaceInFile",
        args = {
            path = "src/main.js",
            search = "  return a - b;",
            replace = "  return a + b;",
        },
    }
    child.lua("tool_call.render_from_memory(chat, ...)", { tool_call_part })

    -- no result
    eq(child.get_line(bufnr, 6), "filepath: src/main.js")
    eq(child.get_line(bufnr, 7), "```")
    eq(child.get_line(bufnr, 8), "```")
end

T["tool_result: ReplaceInFile success message is rendered"] = function()
    child.lua(
        [[chat=require("senpai.presentation.chat.window").new(...)]],
        { { thread_id = "test_render_message_replace_in_file" } }
    )
    child.lua([[chat:show()]])
    local bufnr = child.lua_get([[chat.log_area.bufnr]])

    local tool_call_part = {
        toolName = "ReplaceInFile",
        args = {
            path = "src/main.js",
            search = "  return a - b;",
            replace = "  return a + b;",
        },
    }
    child.lua("tool_call.render_from_memory(chat, ...)", { tool_call_part })

    local tool_result_part = {
        toolName = "ReplaceInFile",
        result = "[replace_in_file] Result:\n\nSuccess",
    }
    child.lua("tool_result.render_from_memory(chat, ...)", { tool_result_part })

    eq(child.get_line(bufnr, 9), "[replace_in_file] Result:")
    eq(child.get_line(bufnr, 10), "")
    eq(child.get_line(bufnr, 11), "Success")
end

T["tool_result: ReplaceInFile error message is rendered"] = function()
    child.lua(
        [[chat=require("senpai.presentation.chat.window").new(...)]],
        { { thread_id = "test_render_message_replace_in_file" } }
    )
    child.lua([[chat:show()]])
    local bufnr = child.lua_get([[chat.log_area.bufnr]])

    local tool_call_part = {
        toolName = "ReplaceInFile",
        args = {
            path = "src/main.js",
            search = "  return a - b;",
            replace = "  return a + b;",
        },
    }
    child.lua("tool_call.render_from_memory(chat, ...)", { tool_call_part })

    local tool_result_part = {
        toolName = "ReplaceInFile",
        result = "[replace_in_file] Result:\n\nError: foo",
    }
    child.lua("tool_result.render_from_memory(chat, ...)", { tool_result_part })

    -- エラーメッセージがdiffブロックの下に表示されているか
    eq(child.get_line(bufnr, 9), "[replace_in_file] Result:")
    eq(child.get_line(bufnr, 10), "")
    eq(child.get_line(bufnr, 11), "Error: foo")
end

return T
