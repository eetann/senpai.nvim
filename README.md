# senpai.nvim
Senpai is super reliable Neovim AI plugin!<br/>
<img width="800" alt="chat" src="https://github.com/user-attachments/assets/4f80c65c-01f7-49aa-a6e5-4963be75666f" />


# Feature

- 💬 Chat
- 📜 History: You can continue the conversation
- 🔌 MCP (Model Context Protocol)
- 📚 RAG (Retrieval Augmented Generation)
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
<img width="312" alt="keymap help for chat" src="https://github.com/user-attachments/assets/8ee2bf91-1602-4441-aedd-59875fe22a83" />

By default, send to AI with `<CR>`.<br/>


### read file
If you write the file name, it will automatically read it.
If you write `foo/bar/buz.txt` as `summarize buz.txt`,
it will be recognized.<br/>
(internally it searches `**/buz.txt` for files under git control).<br/>

Right now it's automatic, but eventually I'm going to make it controllable.


### replace file
You can also edit the file.<br/>
<img width="650" alt="Image" src="https://github.com/user-attachments/assets/c3981de9-3bb4-476d-9e30-1fc5dbf1cafd" />

In the area called `Replace File`, press `a` to display the diff.
This diff uses Neovim's built-in function `diffthis`, so you can apply the diff with `do` or `dp`.
Related help `:help copy-diffs`.
<!-- panvimdoc-ignore-start -->
https://github.com/user-attachments/assets/fa13beb7-3b79-4fb0-9e97-25ee16f81ee0  
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

- `foo`
  - Toggle display of input area
  - default: `gi`

- `help`
  - show chat's keymap help
  - default: `?`

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

- `show_log`
  - *For Developers.* show internal API log
  - default: none

- `show_mcp_tools`
  - *For Developers.* show MCP Tools
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

You can set up servers in `mcp.servers` like this:
```lua
require("senpai").setup({
    mcp = {
        servers = {
            sequential = {
                command = "bunx",
                args = { "-y", "@modelcontextprotocol/server-sequential-thinking" },
            },
            mastra = {
                command = "bunx",
                args = { "-y", "@mastra/mcp-docs-server" }
            },
        },
    },
}) 
```

You can find detailed writing instructions in the type list |`senpai.Config.mcp`|.


## RAG
📚RAG(Retrieval-Augmented Generation) is avaiable. The AI will think of query in the chat on its own.

Supported types:

- URL

URL can be registered with RAG in two ways.

- default keymap `gR` in Chat input area (Key is customizable)
- API `senpai.regist_url_at_rag`

Unnecessary items can be deleted.

<img width="500" alt="Senpai deleteRagSource" src="https://github.com/user-attachments/assets/4adfef4d-92d2-4361-a9b0-f45f0ad7c7c1" />

Cache control can be configured in |`senpai.Config.rag.cache_strategy`|.


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
        gi = "toggle_input",
        gl = "load_thread",
        gx = "new_thread",
        q = "close"
      }
    },
    input_area = {
      keymaps = {
        ["<CR>"] = "submit",
        gR = "regist_url_at_rag"
      }
    },
    log_area = {
      keymaps = {
        a = "apply",
        gs = "show_system_prompt"
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
    default = "openrouter",
    openai = {
      model_id = "gpt-4o"
    },
    openrouter = {
      model_id = "anthropic/claude-3.7-sonnet"
    }
  },
  rag = {
    cache_strategy = "ask"
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
:Senapi _hello
```

For developers.
To check communication with internal servers.


_No arguments_
&nbsp;


## _helloStream
```
:Senapi _helloStream
```

For developers.
To check that streams are received correctly from the internal server.


_No arguments_
&nbsp;


## commitMessage
```
:Senapi commitMessage
```

detail -> |senpai-api-write_commit_message|


| Name | Description |
|------|-------------|
| language | language |

&nbsp;


## deleteRagSource
```
:Senapi deleteRagSource
```

detail -> |senpai-feature-rag|

_No arguments_
&nbsp;


## loadThread
```
:Senapi loadThread
```

detail -> |senpai-feature-history|

_No arguments_
&nbsp;


## newThread
```
:Senapi newThread
```

detail -> |senpai-api-new_thread|

_No arguments_
&nbsp;


## promptLauncher
```
:Senapi promptLauncher
```

detail -> |senpai-api-prompt_launcher|

_No arguments_
&nbsp;


## toggleChat
```
:Senapi toggleChat
```

detail -> |senpai-feature-chat|

_No arguments_
&nbsp;


## transferToChat
```
:Senapi transferToChat
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
```


`*senpai.Config.chat.input_area*`
```lua
---@class senpai.Config.chat.input_area
---@field keymaps? senpai.Config.chat.keymaps
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
---@field model_id ("claude-3-7-sonnet-20250219" | "claude-3-5-sonnet-20241022"|string)
```


`*senpai.Config.provider.base*`
```lua
---@class senpai.Config.provider.base
---@field model_id string
```


`*senpai.Config.provider.openai*`
```lua
---@class senpai.Config.provider.openai: senpai.Config.provider.base
---@field model_id ("gpt-4o" | "gpt-4o-mini"|string)
```


`*senpai.Config.provider.openrouter*`
```lua
---@class senpai.Config.provider.openrouter: senpai.Config.provider.base
---@field model_id string
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
---@field openai? senpai.Config.provider.openai
---@field anthropic? senpai.Config.provider.anthropic
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
