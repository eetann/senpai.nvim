# Adding New Tools to the AI Coding Agent

This document explains how to add new tools to the AI coding agent in senpai.nvim. Tools are special XML tags that the AI can generate in its responses, which are then parsed and processed to provide specific functionality.

## Architecture Overview

The tool system follows this flow:

```
AI Response (XML) → TypeScript Parser → SSE Stream → Lua Frontend → UI Block
```

1. **AI generates XML tags** in its response (e.g., `<execute_command>...</execute_command>`)
2. **TypeScript parser** processes the XML and extracts tool information
3. **Server sends tool results** via Server-Sent Events (SSE) stream
4. **Lua frontend** receives and renders the results as UI blocks
5. **Users interact** with the blocks through action buttons

## Directory Structure

### TypeScript (Server-side)
```
src/
├── usecase/
│   ├── agent/
│   │   └── tool_prompt/       # Tool prompts for AI
│   │       └── get[ToolName]Prompt.ts
│   └── getStreamProcessor/
│       ├── AbstractHandler.ts  # Base class for all handlers
│       ├── [ToolName]Handler.ts
│       └── [ToolName]Handler.test.ts
└── domain/
    └── messageSchema.ts       # Message type definitions
```

### Lua (Client-side)
```
lua/senpai/
├── domain/
│   └── i_block.lua           # Block interface definitions
├── presentation/
│   └── chat/
│       └── [tool_name]_block.lua
├── usecase/
│   └── message/
│       └── tool_result.lua   # Tool result renderer
└── tests/
    └── test_render_message_[tool_name].lua
```

## Step-by-Step Guide to Add a New Tool

### Step 1: Define the Tool Prompt (Optional)

If your tool needs specific AI instructions, create a prompt file:

```typescript
// src/usecase/agent/tool_prompt/get[ToolName]Prompt.ts
export function get[ToolName]Prompt(): string {
  return `\
## tool_name
Description: What this tool does
Parameters:
- param1: (required) Description of parameter 1
- param2: (optional) Description of parameter 2
Usage:
<tool_name>
<param1>value</param1>
<param2>value</param2>
</tool_name>
`;
}
```

### Step 2: Create the TypeScript Handler

Create a new handler that extends `AbstractHandler`:

```typescript
// src/usecase/getStreamProcessor/[ToolName]Handler.ts
import { AbstractHandler } from "./AbstractHandler";
import type { Part } from "../../domain/messageSchema";

export class [ToolName]Handler extends AbstractHandler {
  tagName = "tool_name";  // XML tag name the AI will use
  toolName = "ToolName";  // Tool identifier for frontend
  
  private content = "";
  
  constructor(private writeText: (text: Part) => void) {
    super();
  }
  
  async startTag(): Promise<void> {
    this.content = "";
  }
  
  contentLine(chunk: string): void {
    this.content += chunk;
  }
  
  async endTag(): Promise<void> {
    // Parse content and send tool result
    const result = {
      // Structure your result data here
      data: this.content
    };
    
    this.writeText({
      type: "toolResult" as const,
      toolName: this.toolName,
      result,
    });
  }
}
```

### Step 3: Write Handler Tests

```typescript
// src/usecase/getStreamProcessor/[ToolName]Handler.test.ts
import { describe, it, expect, vi } from "vitest";
import { [ToolName]Handler } from "./[ToolName]Handler";

describe("[ToolName]Handler", () => {
  it("should parse tool content correctly", async () => {
    const writeText = vi.fn();
    const handler = new [ToolName]Handler(writeText);
    
    await handler.startTag();
    handler.contentLine("test content");
    await handler.endTag();
    
    expect(writeText).toHaveBeenCalledWith({
      type: "toolResult",
      toolName: "ToolName",
      result: expect.objectContaining({
        data: "test content"
      }),
    });
  });
});
```

### Step 4: Register the Handler

Add your handler to the processor:

```typescript
// src/usecase/getStreamProcessor/GetStreamProcessor.ts
import { [ToolName]Handler } from "./[ToolName]Handler";

// In the handlers array:
const handlers: AbstractHandler[] = [
  new ReplaceInFileHandler(writeText, this.cwd),
  new ExecuteCommandHandler(writeText),
  new [ToolName]Handler(writeText), // Add your handler here
];
```

### Step 5: Create the Lua Block

```lua
-- lua/senpai/presentation/chat/[tool_name]_block.lua
local IBlock = require("senpai.domain.i_block")

---@class senpai.[ToolName]Block: senpai.IBlock
---@field block_type "tool_name"
---@field data string  -- Add your specific fields
local M = {}
M.__index = M
setmetatable(M, { __index = IBlock })

---@param opts {row:integer, winid:integer, data:string}
---@return senpai.[ToolName]Block
function M.new(opts)
  local self = setmetatable({}, M)
  self.block_type = "tool_name"
  self.row = opts.row
  self.winid = opts.winid
  self.data = opts.data
  
  self:setup()
  return self
end

---@return boolean
function M:has_ui()
  return true  -- Set to false if no UI is needed
end

function M:get_action_buttons()
  return {
    { label = "Apply", description = "Apply this change" },
    { label = "Cancel", description = "Cancel operation" },
  }
end

---@param action_type string
function M:handle_action(action_type)
  if action_type == "Apply" then
    -- Handle apply action
    vim.notify("Applied!")
  elseif action_type == "Cancel" then
    -- Handle cancel action
    self:hide()
  end
end

function M:setup_body()
  -- Set up the UI content
  local lines = {
    "Tool Result:",
    self.data,
  }
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, lines)
end

return M
```

### Step 6: Update Type Definitions

```lua
-- lua/senpai/domain/i_block.lua
-- Add to the block_type alias:
---@alias senpai.block_type "replace_in_file"|"execute_command"|"tool_name"|nil

-- Add block interface if needed:
---@class senpai.I[ToolName]Block: senpai.IBlock
---@field block_type "tool_name"
---@field data string  -- Your specific fields
```

### Step 7: Add Tool Result Type Definition

```lua
-- lua/senpai/domain/message.lua
-- Add the tool result type definition:
---@class senpai.chat.message.result.[tool_name]
---@field data string  -- Your specific fields
---@field otherField string[]
```

### Step 8: Register in Frontend

```lua
-- lua/senpai/usecase/message/tool_result.lua
-- Add in the render_tool_result function:
if part.toolName == "ToolName" then
  local ToolNameBlock = require("senpai.presentation.chat.tool_name_block")
  chat:add_block("tool_name", {
    row = row,
    winid = winid,
    sticky_manager = chat.sticky_manager,
    data = part.result.data,
  })
  return
end
```

### Step 9: Write Lua Tests

```lua
-- tests/test_render_message_[tool_name].lua
local Helpers = dofile("tests/helpers.lua")
local child = Helpers.new_child_neovim()
local expect, eq = Helpers.expect, Helpers.expect.equality

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.lua([[M=require("senpai.usecase.message.assistant")]])
    end,
    post_once = child.stop,
  },
})

T["<tool_name>"] = MiniTest.new_set()

T["tool_result: ToolName block is rendered"] = function()
  child.lua(
    [[chat=require("senpai.presentation.chat.window").new(...)]],
    { { thread_id = "test_render_message_tool_name" } }
  )
  child.lua([[chat:show()]])
  local bufnr = child.lua_get([[chat.log_area.bufnr]])

  local tool_result_part = {
    toolCallId = "ToolName-2025-01-01",
    toolName = "ToolName",
    result = {
      data = "test data",
    },
  }
  child.lua(
    'require("senpai.usecase.message.tool_result").render_from_memory(chat, ...)',
    { tool_result_part }
  )

  -- Verify the tool block was rendered correctly
  eq(child.get_line(bufnr, -3), "> [!NOTE] ToolName")
  eq(child.get_line(bufnr, -2), "> test data")
  eq(child.get_line(bufnr, -1), "")
end

return T
```

The `child.lua_get` can only be used to get a variable.
To get the return value after processing multiple lines, write `return` in `child.lua` as follows.
```lua
local popup_count = child.lua([[
  local count = 0
  for popup in pairs(chat.sticky_popup_manager.popups) do
    count = count + 1
  end
  return count
]])
```

To run a specific test file:
```sh
nvim --headless --noplugin -u ./scripts/test/minimal_init.lua -c "lua MiniTest.run_file('tests/test_render_message_[tool_name].lua')"
```

## Reference Files

### Core Components
- **Abstract Handler**: `src/usecase/getStreamProcessor/AbstractHandler.ts` - Base class for all parsers
- **Block Interface**: `lua/senpai/domain/i_block.lua` - Base interface for UI blocks
- **Tool Result Handler**: `lua/senpai/usecase/message/tool_result.lua` - Dispatches tool results to blocks

### Example Implementations
- **Simple Tool (No UI)**: 
  - Handler: `src/usecase/getStreamProcessor/ExecuteCommandHandler.ts`
  - Block: `lua/senpai/presentation/chat/execute_command_block.lua`
  
- **Complex Tool (With UI)**:
  - Handler: `src/usecase/getStreamProcessor/ReplaceInFileHandler.ts`
  - Block: `lua/senpai/presentation/chat/replace_in_file_block.lua`

## Key Concepts

### Handler Responsibilities
- Parse XML content from AI responses
- Validate and structure the data
- Send tool results via `writeText` callback
- Handle sub-tags if needed (using `handlers` map)

### Block Responsibilities
- Render UI (if `has_ui()` returns true)
- Define and handle action buttons
- Manage lifecycle (setup, mount, show, hide)
- Interact with other Neovim components

### UI-less Blocks
Some tools don't need a UI block (e.g., `execute_command`). For these:
- Set `has_ui()` to return `false`
- Skip UI-related methods
- Results are typically added directly to the chat log

## Testing

1. **Unit Tests**: Test handlers and blocks in isolation
2. **Integration Tests**: Test the full flow from AI response to UI
3. **Manual Testing**: 
   - Start dev server: `pnpm run dev`
   - Launch test Neovim: `mise run launch`
   - Trigger your tool and verify behavior

## Important Implementation Notes

### Tool Result Type Definitions
When adding a new tool, you **must** add the tool result type definition to `lua/senpai/domain/message.lua`:

```lua
---@class senpai.chat.message.result.[tool_name]
---@field field1 string
---@field field2 string[]
```

This ensures proper type checking and IDE support throughout the Lua codebase.

### Handler Registration Order
The order of handlers in `GetStreamProcessor.ts` doesn't matter functionally, but keep them alphabetically sorted for maintainability.

### UI vs UI-less Blocks
- **UI-less blocks** (like `execute_command`): Set `has_ui()` to return `false`, skip UI setup
- **UI blocks** (like `ask_followup_question`): Implement full UI lifecycle methods

### Error Handling in Blocks
Always handle potential errors in action handlers:

```lua
function M:handle_action(action_type)
  local ok, result = pcall(function()
    -- Your action logic here
  end)
  
  if not ok then
    vim.notify("Error: " .. tostring(result), vim.log.levels.ERROR)
    return
  end
end
```

### Testing Considerations
- Test both empty and populated data scenarios
- Verify action button generation for edge cases
- Test the full integration flow from tool result to UI interaction

## Common Patterns

### Handling Complex Content
For tools with structured content, parse in the handler:

```typescript
async endTag(): Promise<void> {
  const lines = this.content.trim().split('\n');
  const parsed = {
    field1: lines[0],
    field2: lines[1],
    // ...
  };
  
  this.writeText({
    type: "toolResult",
    toolName: this.toolName,
    result: parsed,
  });
}
```

### Error Handling
Always validate input and handle errors gracefully:

```typescript
async endTag(): Promise<void> {
  try {
    // Parse and validate
    if (!this.content) {
      throw new Error("Empty content");
    }
    // Process...
  } catch (error) {
    this.writeText({
      type: "toolResult",
      toolName: this.toolName,
      result: { error: error.message },
    });
  }
}
```
