# senpai.nvim
Senpai is super reliable Neovim AI plugin!<br/>
<img width="800" alt="chat" src="https://github.com/user-attachments/assets/4f80c65c-01f7-49aa-a6e5-4963be75666f" />


# Feature

- 💬 Chat
- 📜 History: You can continue the conversation
- 🔌 MCP (Model Context Protocol)
- 📚 RAG (Retrieval Augmented Generation)
- 📌 Setting Project Rules
- 🧩 Prompt Launcher: Open chat with pre-defined prompts
- 🪄 Generate commit message

Powered by [Mastra](https://mastra.ai/) and [Vercel AI SDK](https://sdk.vercel.ai/).


## Chat
💬You can chat with AI.<br/>
<!-- panvimdoc-ignore-start -->
https://github.com/user-attachments/assets/52731339-518a-4964-ad36-3959fe51238e  
<!-- panvimdoc-ignore-end -->
You can toggle the chat window with `:Senpai toggleChat`.


### chat help
**You can open keymap help with `?`**.<br/>
<img width="317" alt="keymap help for chat" src="https://github.com/user-attachments/assets/67151e6d-a339-4ea4-9587-f2706af1eb8c" />

By default, send to AI with `<CR>`.<br/>


### read file
There are two ways to load files: "Link format" and "Automatic".


#### Link format
Entering `/file` will open the finder and allow you to preview and select the file you wish to attach. The currently supported plugins are as follows

- completion plugin
    - [blink.cmp](https://github.com/Saghen/blink.cmp)
- finder
    - [snacks.nvim](https://github.com/folke/snacks.nvim) picker

Links can be inserted manually without a plugin.

```txt
Explain [foo.txt](/workspace/foo.txt)
```

File paths can be absolute or relative, such as starting with `./`.


#### Automatic
If you write the file name without mention, it will automatically read it.
If you write `foo/bar/buz.txt` as `summarize buz.txt`,
it will be recognized.<br/>
(internally it searches `**/buz.txt` for files under git control).<br/>

**This one does not apply the per-file rules of the project** (explained later).


### replace file
You can also edit the file.<br/>
<img width="650" alt="Image" src="https://github.com/user-attachments/assets/c3981de9-3bb4-476d-9e30-1fc5dbf1cafd" />

In the area called `Replace File`, press `a` to display the diff.
The keymap in diff mode is as follows.

| key  | description                            |
| ---- | -------------------------------------- |
| `q`  | quit diff mode                         |
| `ga` | accept AI code                         |
| `gA` | accept All AI code and quit diff mode  |
| `gr` | reject AI code                         |
| `gR` | reject All AI code and quit diff mode  |

The keymap in diff mode is temporary, so it will return to the original keymap when diff mode ends.
<!-- panvimdoc-ignore-start -->
https://github.com/user-attachments/assets/02dbab59-4af8-4a32-af79-574112df0180  
<!-- panvimdoc-ignore-end -->

### system prompt
If you want to write a system prompt, you can configure it as follows.

```lua
require("senpai").setup({
    chat = {
        system_prompt = "Answers should be in Japanese."
    }
})
```

To see the system prompt, type `gs` in the chat log area (Key is customizable).<br/>
<img width="772" alt="Image" src="https://github.com/user-attachments/assets/04ba00bd-1c39-470b-9b83-6c3607fb16ba" />


## Chat Keymaps
You can set up a keymap for Chat with the following three.

- `chat.common.keymaps`: common in log area and input area
- `chat.log_area.keymaps`: for log area
- `chat.input_area.keymaps`: for input area

```lua
require("senpai").setup({
    chat = {
        input_area = {
            keymaps = {
                ["gT"] = "load_thread",
                ["<CR><CR>"] = "submit",
                ["<CR>"] = false,
            },
        },
    },
})
```
Assign `false` if you want to delete the keymap.

All actions can be performed from Help(`?`).

The names of the actions that can be written in the keymaps table are.
<!-- auto-generate-s:chat_action -->

- `abort`
  - Abort the current interaction with the LLM
  - default: `<C-c>`

- `apply`
  - Apply the contents of the `Replace File` block to a file
  - default: `a` in log area

- `close`
  - close chat
  - default: `q`

- `copy_input_or_codeblock`
  - copy user input or replace file block
  - default: `gy` in log area

- `foo`
  - Toggle display of input area
  - default: `gi`

- `help`
  - show chat's keymap help
  - default: `?`

- `jump_to_next_block`
  - jump to next user input or replace file block
  - default: `]]`

- `jump_to_previous_block`
  - jump to previous user input or replace file block
  - default: `[[`

- `load_thread`
  - load thread. detail -> |senpai-feature-history|
  - default: `gl`

- `new_thread`
  - replace new thread. detail -> |senpai-api-new_thread|
  - default: `gx`

- `open_api_doc`
  - *For Developers.* Open internal API docs. You can call the API immediately!
  - default: none

- `regist_url_at_rag`
  - Fetch URL and save to RAG
  - default: `gR` in input area

- `show_internal_log`
  - *For Developers.* show internal API log
  - default: none

- `show_mcp_tools`
  - *For Developers.* show MCP Tools
  - default: none

- `show_replace_content`
  - *For Developers.* show Replace File content.
  - default: none

- `show_system_prompt`
  - Show system prompt associated with current chat
  - default: `gs` in log area

- `submit`
  - Send the text in the input area to the LLM
  - default: `<CR>` in input area
<!-- auto-generate-e:chat_action -->


## History
📜Select a past thread and load it again as a chat.<br/>
**You can continue the conversation**.
`:Senpai loadThread` opens the chat list.  
<!-- panvimdoc-ignore-start -->
https://github.com/user-attachments/assets/1ba4b2e6-2a7d-4b1f-ac88-72aab92a95ff  
<!-- panvimdoc-ignore-end -->
The selection UI supports the following methods.  

- Native (vim.ui.select)
- [snacks.nvim](https://github.com/folke/snacks.nvim) picker

<img width="1671" alt="Senpai loadThread" src="https://github.com/user-attachments/assets/5289e694-c942-496a-ac5c-0786e726c166" />

### delete thread from history
In case of snacks, switch to normal mode and enter `dd` to delete the specified thread.<br/>
You can also delete using the API `senpai.delete_thread(thread_id)`.


## MCP
🔌MCP(Model Context Protocol) is avaiable. The AI will think of the MCP tool calls in the chat on its own.

MCP configuration can be written in two places.

- `require("senpai").setup`: write configuration common to all projects in Lua
- `.senpai/mcp.json`: Project-specific configuration in json

### configuration in plugin setup
You can set up servers in `mcp.servers` like this:
```lua
require("senpai").setup({
    mcp = {
        servers = {
            sequential = {
                command = "bunx",
                args = { "-y", "@modelcontextprotocol/server-sequential-thinking" },
            },
        },
    },
}) 
```

You can find detailed writing instructions in the type list |`senpai.Config.mcp`|.


### configuration in project
You can set up servers in `.senpai/mcp.json` like this:
```json
{
	"mcpServers": {
		"mastra": {
			"command": "bunx",
			"args": ["-y", "@mastra/mcp-docs-server"]
		},
		"daisyUi": {
			"command": "bunx",
			"args": ["-y", "sitemcp", "https://daisyui.com", "-m", "/components/**"]
		}
	}
}
```


## RAG
📚RAG(Retrieval-Augmented Generation) is avaiable if the environment variable `OPENAI_API_KEY` is set . If you want to use RAG, please make a mention like `@rag`.

```txt
@rag Tell me about mdx.
```

If you are not comfortable with mentions, set `rag.mode` to `“auto”` in the settings, \
and the AI will determine when to use it on its own.
But you have to understand that AI often does RAG searches for nothing.

Supported types:

- URL

URL can be registered with RAG in two ways.

- default keymap `gR` in Chat input area (Key is customizable)
- API `senpai.regist_url_at_rag`

Unnecessary items can be deleted.

<img width="500" alt="Senpai deleteRagSource" src="https://github.com/user-attachments/assets/4adfef4d-92d2-4361-a9b0-f45f0ad7c7c1" />

Cache control can be configured in |`senpai.Config.rag.cache_strategy`|.


## Project Rules
📌Rules can be set for each project.

The rule prompts are the `./senpai/prompts/` directory as mdx files.

```
./senpai/prompts/
├── project.mdx
├── inquiry.mdx
└── calendar.mdx
```

Write the following.
```markdown
---
description: "Front-end side of senpai.nvim"
globs: "lua/senpai/**/*.lua"
---

First, when you refer to this sentence, greet it with "I love Neovim!"

You are a professional Neovim plugin developer and are familiar with Lua.
```

The following elements can be written in the frontmatter.

- description: `string`. description for human
- (optional)globs: `string|string[]|undefined`.
    - Write the glob of the file to which you want to apply the prompt for that file
    - See [Supported Glob Patterns(Bun Docs)](https://bun.sh/docs/api/glob#supported-glob-patterns) for how to write supported globs


If you want to rewrite and apply the project rules file, do one of the following
- The command `:Senpai reloadRules`
- Restart Neovim


## Prompt Launcher
🧩You can chat with customized prompts.

```lua
require("senpai").setup({
  prompt_launchers = {
    ["Tsundere"] = {
      system = "Answers should be tsundere style.",
      priority = 100,
    },
    ["test message"] = {
      user = "test message. Hello!",
    },
  },
}) 
```

Command `:Senpai promptLauncher` opens the selection UI. The chosen one opens as a chat.<br/>
<img width="800" alt="Senpai promptLauncher" src="https://github.com/user-attachments/assets/3db4369f-9579-4d5a-8f9b-e737735b937b" />


## Generate commit message
🪄You can generate a conventional commit message with the following command in `.git/COMMIT_EDITMSG`.
```
:Senpai commitMessage
:Senpai commitMessage Japanese
```

Language names need not be exact. They are free. For example, you can use something like this. :)
```
:Senpai commitMessage English(Tsundere)
```

Here's a code of my setup in `.config/nvim/after/ftplugin/gitcommit.lua`.
```lua
vim.keymap.set("n", "<C-g><C-g>", function()
	if vim.env.COMMIT_MESSAGE_ENGLISH == "1" then
		vim.cmd("Senpai commitMessage English")
	else
		vim.cmd("Senpai commitMessage Japanese")
	end
end, { buffer = true, desc = "Senpai commitMessage" })
```


# Requirements

- Neovim
- curl
- [Bun](https://bun.sh/)
    - Forgive me if the dependence is frustrating for you, but it's easy to install.
- Dependent Plugins
    - [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
    - [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
    - [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)


# Installation
with [Lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "eetann/senpai.nvim", 
    build = "bun install",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
	opts = {}
}
```
with [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
{
    "eetann/senpai.nvim", 
    run = "bun install",
    requires = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
	opt = true,
    config = function()
        require("senpai").setup({}) 
    end
}
```

**Example of lazy.nvim lazy loading**
It is useful to set `:Senpai toggleChat`!

```lua
{
    "eetann/senpai.nvim", 
    keys = {
        { "<space>ss", "<Cmd>Senpai toggleChat<CR>" },
        { "<space>sl", "<Cmd>Senpai promptLauncher<CR>" },
		{ "<space>sv", "<Cmd>Senpai transferToChat<CR>", mode = "v" },
    },
    cmd = { "Senpai" },
    opts = {config}
}
```


## Provider
Currently supported providers are as follows.

| name         | Environment variable for API token |
|--------------|------------------------------------|
| `anthropic`  | `ANTHROPIC_API_KEY`                |
| `deepseek`   | `DEEPSEEK_API_KEY`                 |
| `google`     | `GOOGLE_GENERATIVE_AI_API_KEY`     |
| `openai`     | `OPENAI_API_KEY`                   |
| `openrouter` | `OPENROUTER_API_KEY`               |

The default provider is written in `providers.default`.
```lua
require("senpai").setup({
  providers = {
    default = "openrouter",
  },
})
```

The model specifications should be written in the `model_id` of each provider.
```lua
require("senpai").setup({
  providers = {
    default = "openrouter",
    openrouter = { model_id = "openai/chatgpt-4o-latest" },
  },
})
```

You can find how to write `model_id` in the following links (most of them are in the Vercel AI SDK documentation).

- [Anthropic](https://sdk.vercel.ai/providers/ai-sdk-providers/anthropic#model-capabilities)
- [DeepSeek](https://sdk.vercel.ai/providers/ai-sdk-providers/deepseek#model-capabilities)
- [Google](https://sdk.vercel.ai/providers/ai-sdk-providers/google-generative-ai#model-capabilities)
- [OpenAI](https://sdk.vercel.ai/providers/ai-sdk-providers/openai#model-capabilities)
- ...
- [OpenRouter](https://openrouter.ai/models)





# config

## default config
The default config are as follows.

<!-- panvimdoc-ignore-start -->
<details>
    <summary>default config</summary>
<!-- panvimdoc-ignore-end -->

<!-- auto-generate-s:default_config -->
```lua
{
  chat = {
    common = {
      keymaps = {
        ["<C-c>"] = "abort",
        ["?"] = "help",
        ["[["] = "jump_to_previous_block",
        ["]]"] = "jump_to_next_block",
        gi = "toggle_input",
        gl = "load_thread",
        gx = "new_thread",
        q = "close"
      },
      width = 80
    },
    input_area = {
      height = "25%",
      keep_file_attachment = true,
      keymaps = {
        ["<CR>"] = "submit",
        gR = "regist_url_at_rag"
      }
    },
    log_area = {
      keymaps = {
        a = "apply",
        gs = "show_system_prompt",
        gy = "copy_input_or_codeblock"
      }
    }
  },
  commit_message = {
    language = "English"
  },
  debug = false,
  mcp = {
    servers = {}
  },
  prompt_launchers = {
    Senpai = {
      priority = 99,
      system = "Answer as a senpai with a crazy casual tone."
    },
    Tsundere = {
      priority = 100,
      system = "Answers should be tsundere style."
    }
  },
  providers = {
    anthropic = {
      model_id = "claude-3-7-sonnet-20250219"
    },
    deepseek = {
      model_id = "deepseek-chat"
    },
    default = "openrouter",
    google = {
      model_id = "gemini-1.5-pro"
    },
    openai = {
      model_id = "gpt-4.1-mini"
    },
    openrouter = {
      model_id = "anthropic/claude-3.7-sonnet"
    }
  },
  rag = {
    cache_strategy = "ask",
    mode = "mention"
  }
}
```
<!-- auto-generate-e:default_config -->

<!-- panvimdoc-ignore-start -->
</details>
<!-- panvimdoc-ignore-end -->

## transfer keymap
You can transfer the selection to the chat input area by setting up a keymap as follows.
```lua
vim.keymap.set("v", "<space>sv", 
    function()
        require("senpai.api").transfer_visual_to_chat()
    end,
    { desc = "[senpai] transfer_visual_to_chat" }
)
```


For lazy.nvim, it is convenient to write in `keys`.
```lua
{
    "eetann/senpai.nvim", 
    keys = {
        -- ...
        {
            "<space>sv",
            function()
                require("senpai.api").transfer_visual_to_chat()
            end,
            mode = "v",
			desc = "[senpai] transfer_visual_to_chat",
        },
    },
}
```


## with render-markdown.nvim
If you are using a plugin that renders markdown like [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim), 
it would be useful to add the following file type specification.

```lua
return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown", "mdx", "senpai_chat_log", "senpai_chat_input" },
    -- ...
}
```


## with status plugin
If you have a status plugin or winbar set up,
I recommend that you do not set it up in the senpai.nvim buffer.

For example, for [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim), you could set the following
```lua
require("lualine").setup({
    options = {
        disabled_filetypes = {
            winbar = {
                "senpai_chat_log",
                "senpai_chat_input",
                "senpai_ai_buffer",
            },
        },
    },
})
```


# API
For simplicity, this document uses the following definition:
```lua
local senpai = require("senpai.api")
```

<!-- panvimdoc-ignore-start -->
<details>
    <summary>API</summary>
<!-- panvimdoc-ignore-end -->
<!-- auto-generate-s:api -->

## delete_rag_source
```lua
senpai.delete_rag_source()
senpai.delete_rag_source(source)
```
detail -> |senpai-feature-rag|


| Name | Type | Description |
|------|------|-------------|
| source | string? | If not specified, the finder will open |

&nbsp;


## delete_thread
```lua
senpai.delete_thread(thread_id)
```
Delete the specified thread.


| Name | Type | Description |
|------|------|-------------|
| thread_id | string | thread_id |

&nbsp;


## generate_commit_message
```lua
senpai.generate_commit_message(language)
```
AI generate conventional commit message of commitizen convention format.


| Name | Type | Description |
|------|------|-------------|
| language | string | Language of commit message |
| callback | senpai.RequestHandler.callback | Function to be processed using the response |

&nbsp;


## load_thread
```lua
senpai.load_thread()
senpai.load_thread(thread)
```
detail -> |senpai-feature-history|


| Name | Type | Description |
|------|------|-------------|
| thread_id | string? | If not specified, the finder will open |

&nbsp;


## new_thread
```lua
senpai.new_thread()
```
Open new chat.

_No arguments_
&nbsp;


## prompt_launcher
```lua
senpai.prompt_launcher()
```
Select and launch the prompt_launcher set in \|senpai.Config.prompt_launchers\|.

_No arguments_
&nbsp;


## regist_url_at_rag
```lua
senpai.regist_url_at_rag()
senpai.regist_url_at_rag(url)
```
Fetch URL and save to RAG.
Cache control can be configured in \|senpai.Config.rag.cache_strategy\|.


| Name | Type | Description |
|------|------|-------------|
| url | string\|nil | URL. If not specified, the input UI will open |
| no_cache | boolean\|nil | If set to true, no cache is used regardless of Config. |

&nbsp;


## reload_rules
```lua
senpai.reload_rules()
```
Reload Project rules and MCP settings

_No arguments_
&nbsp;


## setup
```lua
senpai.setup({...})
```
Setup senpai


| Name | Type | Description |
|------|------|-------------|
| config | \|`senpai.Config`\| | Setup senpai |

&nbsp;


## toggle_chat
```lua
senpai.toggle_chat()
```
Toggle chat.

_No arguments_
&nbsp;


## transfer_visual_to_chat
```lua
senpai.transfer_visual_to_chat()
```
Transfers the selected range in visual mode to the chat input area.
If the chat buffer is not open, it will be opened.

_No arguments_
&nbsp;


## write_commit_message
```lua
senpai.write_commit_message(language)
```
AI write conventional commit message of commitizen convention format.


| Name | Type | Description |
|------|------|-------------|
| language | string | Language of commit message |

&nbsp;

<!-- auto-generate-e:api -->
<!-- panvimdoc-ignore-start -->
</details>
<!-- panvimdoc-ignore-end -->

# Commands
`:Senpai {subcommand}`

<!-- auto-generate-s:command -->

## _hello
```
:Senpai _hello
```

For developers.
To check communication with internal servers.


_No arguments_
&nbsp;


## _helloStream
```
:Senpai _helloStream
```

For developers.
To check that streams are received correctly from the internal server.


_No arguments_
&nbsp;


## commitMessage
```
:Senpai commitMessage
```

detail -> |senpai-api-write_commit_message|


| Name | Description |
|------|-------------|
| language | language |

&nbsp;


## deleteRagSource
```
:Senpai deleteRagSource
```

detail -> |senpai-feature-rag|

_No arguments_
&nbsp;


## loadThread
```
:Senpai loadThread
```

detail -> |senpai-feature-history|

_No arguments_
&nbsp;


## newThread
```
:Senpai newThread
```

detail -> |senpai-api-new_thread|

_No arguments_
&nbsp;


## promptLauncher
```
:Senpai promptLauncher
```

detail -> |senpai-api-prompt_launcher|

_No arguments_
&nbsp;


## reloadRules
```
:Senpai reloadRules
```

detail -> |senpai-api-reload_rules|

_No arguments_
&nbsp;


## toggleChat
```
:Senpai toggleChat
```

detail -> |senpai-feature-chat|

_No arguments_
&nbsp;


## transferToChat
```
:Senpai transferToChat
```

detail -> |senpai-api-transfer_visual_to_chat|

_No arguments_
&nbsp;

<!-- auto-generate-e:command -->

# Type
<!-- panvimdoc-ignore-start -->
<details>
    <summary>Types</summary>
<!-- panvimdoc-ignore-end -->
<!-- auto-generate-s:type -->

`*senpai.Config*`
```lua
---@class senpai.Config
---@field providers? senpai.Config.providers
---@field commit_message? senpai.Config.commit_message
---@field chat? senpai.Config.chat
---@field rag? senpai.Config.rag
---@field prompt_launchers? senpai.Config.prompt_launchers
---@field mcp? senpai.Config.mcp
---@field debug? boolean
```


`*senpai.Config.chat*`
```lua
---@class senpai.Config.chat
---@field common? senpai.Config.chat.common
---@field log_area? senpai.Config.chat.log_area
---@field input_area? senpai.Config.chat.input_area
---@field system_prompt? string
```


`*senpai.Config.chat.action*`
```lua
---@alias senpai.Config.chat.action
---|false
---|senpai.Config.chat.actions # detail -> |senpai-feature-chat-keymaps|
---|senpai.Config.chat.keymap
```


`*senpai.Config.chat.common*`
```lua
---@class senpai.Config.chat.common
---@field keymaps? senpai.Config.chat.keymaps
---@field width? number|string column number or width percentage string for chat window
---  width = 50 -- 50 column number
---  width = 40% -- 40% chat window width relative to editor
```


`*senpai.Config.chat.input_area*`
```lua
---@class senpai.Config.chat.input_area
---@field keymaps? senpai.Config.chat.keymaps
---@field height? number|string row number or height percentage string for input area
---  height = 5 -- 5 row number
---  height = 25% -- 25% input area height relative to chat window
---@field keep_file_attachment? boolean
--- If set to true, files are automatically attached in the next message when attached.
```


`*senpai.Config.chat.keymap*`
```lua
---@class senpai.Config.chat.keymap
---@field [1]? string|fun(self: senpai.IChatWindow):nil
---@field key? string
---@field mode? string|string[]
---@field desc string
```


`*senpai.Config.chat.keymaps table<string, senpai.Config.chat.action>*`
```lua
---@alias senpai.Config.chat.keymaps table<string, senpai.Config.chat.action>
```


`*senpai.Config.chat.log_area*`
```lua
---@class senpai.Config.chat.log_area
---@field keymaps? senpai.Config.chat.keymaps
```


`*senpai.Config.commit_message*`
```lua
---@class senpai.Config.commit_message
---@field language string|(fun(): string) Supports languages that AI knows
---   It doesn't have to be strictly natural language,
---   since the prompt is as follows
---    `subject and body should be written in ${language}.`
---   That means the AI can write it in a tsundere style as well.
---   Like this.
---     `:Senpai commitMessage English(Tsundere)`
```


`*senpai.Config.mcp*`
```lua
---@class senpai.Config.mcp
---@field servers? table<string, senpai.Config.mcp.server>
--- server name is as follows: `[0-9a-zA-Z-_]`
--- OK: `mastraDocs`
--- NG: `mastra docs`
```


`*senpai.Config.mcp.server*`
```lua
---@alias senpai.Config.mcp.server
---| senpai.Config.mcp.server.stdio
---| senpai.Config.mcp.server.sse
```


`*senpai.Config.mcp.server.sse*`
```lua
---@class senpai.Config.mcp.server.sse
---@field url string
```


`*senpai.Config.mcp.server.stdio*`
```lua
---@class senpai.Config.mcp.server.stdio
---@field command string
---@field args? string[]
---@field env? table<string, string>
---@field cwd? string
```


`*senpai.Config.provider.anthropic*`
```lua
---@class senpai.Config.provider.anthropic: senpai.Config.provider.base
---@field model_id ("claude-3-7-sonnet-20250219"|"claude-3-5-sonnet-20241022"|string)
```


`*senpai.Config.provider.base*`
```lua
---@class senpai.Config.provider.base
---@field model_id string
```


`*senpai.Config.provider.deepseek*`
```lua
---@class senpai.Config.provider.deepseek: senpai.Config.provider.base
---@field model_id ("deepseek-chat"|"deepseek-reasoner"|string)
--- deepseek-reasoner is DeepSeek-R1. Since structured output is not possible,
--- commit message generation cannot be used with deepseek-reasoner.
```


`*senpai.Config.provider.google*`
```lua
---@class senpai.Config.provider.google: senpai.Config.provider.base
---@field model_id ("gemini-2.5-pro-exp-03-25"|"gemini-2.0-flash-001"|string)
```


`*senpai.Config.provider.name*`
```lua
---@alias senpai.Config.provider.name
---| "anthropic"
---| "deepseek"
---| "google"
---| "openai"
---| "openrouter"
```


`*senpai.Config.provider.openai*`
```lua
---@class senpai.Config.provider.openai: senpai.Config.provider.base
---@field model_id ("gpt-4.1"|"gpt-4.1-mini"|"gpt-4o"|"gpt-4o-mini"|string)
```


`*senpai.Config.provider.openrouter*`
```lua
---@class senpai.Config.provider.openrouter: senpai.Config.provider.base
---@field model_id ("openai/gpt-4.1"|string)
---   You can get a list of models with the following command.
---   >sh
---   curl https://openrouter.ai/api/v1/models | jq '.data[].id'
---   # check specific model
---   curl https://openrouter.ai/api/v1/models | \
---     jq '.data[] | select(.id == "deepseek/deepseek-r1:free") | .'
--- <
```


`*senpai.Config.provider.settings*`
```lua
---@class senpai.Config.provider.settings
---@field anthropic? senpai.Config.provider.anthropic
---@field deepseek? senpai.Config.provider.deepseek
---@field google? senpai.Config.provider.google
---@field openai? senpai.Config.provider.openai
---@field openrouter? senpai.Config.provider.openrouter
---@field [string] senpai.Config.provider.base
```


`*senpai.Config.providers*`
```lua
---@class senpai.Config.providers: senpai.Config.provider.settings
---@field default senpai.Config.provider.name|string
```


`*senpai.Config.rag*`
```lua
---@class senpai.Config.rag
---@field cache_strategy? senpai.Config.rag.cache_strategy
---@field mode? "mention"|"auto"
```


`*senpai.Config.rag.cache_strategy*`
```lua
---@alias senpai.Config.rag.cache_strategy
---| "use_cache"
---| "no_cache"
---| "ask"
```

<!-- auto-generate-e:type -->
<!-- panvimdoc-ignore-start -->
</details>
<!-- panvimdoc-ignore-end -->

# Acknowledgements
This plugin was inspired by the following.

- [codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim): Default keymaps and Implementation of diff display
- [avante.nvim](https://github.com/yetone/avante.nvim): Use of winbar and virt text in chat windows
- [nvim-deck](https://github.com/hrsh7th/nvim-deck): Scripts for creating README and Help
- [cline](https://github.com/cline/cline): How to prompt and edit files

Thanks to all those involved in these!
