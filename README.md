# senpai.nvim
Senpai is super reliable Neovim AI plugin!


# Feature

- 💬 Chat
- 📜 History: You can continue the conversation
- ✅ Generate commit message


## Chat
<img width="1756" alt="chat" src="https://github.com/user-attachments/assets/e981ad2c-1d63-4f45-a30a-80885f557d26" />
You can chat with AI.<br/>

### chat help
You can open keymap help with `?`.<br/>
<img width="312" alt="keymap help for chat" src="https://github.com/user-attachments/assets/8ee2bf91-1602-4441-aedd-59875fe22a83" />

By default, send to AI with `<CR>`.<br/>

### read file
If you write the file name, it will automatically read it.
If you write `foo/bar/buz.txt` as `summarize buz.txt`,
it will be recognized.<br/>
(internally it searches `**/buz.txt` for files under git control).<br/>

Right now it's automatic, but eventually I'm going to make it controllable.


## History
Select a past thread and load it again as a chat.<br/>
**You can continue the conversation**.
The selection UI supports the following methods.<br/>

- Native (vim.ui.select)
- [snacks.nvim](https://github.com/folke/snacks.nvim) picker

<img width="1671" alt="Senpai loadThread" src="https://github.com/user-attachments/assets/5289e694-c942-496a-ac5c-0786e726c166" />

### delete thread from history
In case of snacks, switch to normal mode and enter `dd` to delete the specified thread.<br/>
You can also delete using the API `senpai.delete_thread(thread_id)`.


# Requirements

- Neovim
- curl
- [Bun](https://bun.sh/)
    - Forgive me if the dependence is frustrating for you, but it's easy to install.


# Installation
with [Lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
    "eetann/senpai.nvim", 
	opts = {config}
}
```
with [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
{
    "eetann/senpai.nvim", 
	opt = true,
    config = function()
        require("senpai").setup({config}) 
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
	},
	cmd = { "Senpai" },
	opts = {config}
}
```

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
        gl = "load_thread",
        gx = "new_thread",
        q = "close"
      }
    },
    input_area = {
      keymaps = {
        ["<CR>"] = "submit"
      }
    },
    log_area = {
      keymaps = {}
    }
  },
  commit_message = {
    language = "English"
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
  }
}
```
<!-- auto-generate-e:default_config -->

<!-- panvimdoc-ignore-start -->
</details>
<!-- panvimdoc-ignore-end -->

## changing the chat keymap

Assign `false` if you want to delete the keymap.
```lua
require("senpai").setup({
    chat = {
        input_area = {
            keymaps = {
                ["<CR>"] = false,
                ["<CR><CR>"] = "submit",
            },
        },
    },
})
```

# API
<!-- panvimdoc-ignore-start -->
<details>
    <summary>API</summary>
<!-- panvimdoc-ignore-end -->
<!-- auto-generate-s:api -->

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
```
detail -> |senpai-feature-history|


_No arguments_
&nbsp;


## new_thread
```lua
senpai.new_thread()
```
Open new chat.


_No arguments_
&nbsp;


## setup
```lua
senpai.setup({...})
```
Setup senpai



| Name | Type | Description |
|------|------|-------------|
| config | `\|senpai.Config\|` | Setup senpai |

&nbsp;


## toggle_chat
```lua
senpai.toggle_chat()
```
Toggle chat.


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


## toggleChat
```
:Senapi toggleChat
```

detail -> |senpai-feature-chat|

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
```


`*senpai.Config.chat*`
```lua
---@class senpai.Config.chat
---@field common? senpai.Config.chat.common
---@field log_area? senpai.Config.chat.log_area
---@field input_area? senpai.Config.chat.input_area
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
---@field [1]? string|fun(self: senpai.ChatWindow.Config):nil
---@field key? string
---@field mode? string|string[]
---@field desc string
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

<!-- auto-generate-e:type -->
<!-- panvimdoc-ignore-start -->
</details>
<!-- panvimdoc-ignore-end -->

# Acknowledgements
This plugin was inspired by the following.

- [codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim): Default keymaps and Implementation of diff display
- [avante.nvim](https://github.com/yetone/avante.nvim): Use of winbar and virt text in chat windows
- [nvim-deck: nvim-deck](https://github.com/hrsh7th/nvim-deck): Scripts for creating README and Help

Thanks to all those involved in these.
