# senpai.nvim
Senpai is super reliable Neovim AI plugin!


# Feature
## Chat
![chat](https://github.com/user-attachments/assets/93053937-325b-4ed3-bce5-0215285fdb29)
You can chat with AI.
If you write the file name, it will automatically read it.
If you write `foo/bar/buz.txt` as `summarize buz.txt`,
it will be recognized.
(internally it searches `**/buz.txt` for files under git control).

## History
Select a past thread and load it again as a chat.
You can continue the conversation.
The selection UI supports the following methods.

- Native (vim.ui.select)
- [snacks.nvim](https://github.com/folke/snacks.nvim) picker

![Senpai loadThread](https://github.com/user-attachments/assets/734a759d-5251-465b-8aef-76060979acec)

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
	lazy = true,
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

# Default config
<!-- auto-generate-s:default_config -->
```lua
{
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

# API
<!-- auto-generate-s:api -->

## generate_commit_message
  ```lua
  senpai.generate_commit_message(language)
  ````
  AI generate conventional commit message of commitizen convention format.
  


| Name | Type | Description |
|------|------|-------------|
| language | string | Language of commit message |
| callback | senpai.RequestHandler.callback | Function to be processed using the response |

&nbsp;


## load_thread
  ```lua
  senpai.load_thread()
  ````
  detail -> |senpai-feature-history|
  

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
  ````
  Toggle chat.
  

_No arguments_
&nbsp;


## write_commit_message
  ```lua
  senpai.write_commit_message(language)
  ````
  AI write conventional commit message of commitizen convention format.
  


| Name | Type | Description |
|------|------|-------------|
| language | string | Language of commit message |

&nbsp;

<!-- auto-generate-e:api -->
# Commands
`:Senpai {subcommand}`

<!-- auto-generate-s:command -->

## commitMessage
```
:Senapi commitMessage
```

detail -> |senpai-api-write_commit_message|


| Name | Description |
|------|-------------|
| language | language |

&nbsp;


## openHistory
```
:Senapi openHistory
```

detail -> |senpai-feature-history|

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
<!-- auto-generate-s:type -->

`*senpai.Config*`
```lua
---@class senpai.Config
---@field providers? senpai.Config.providers
---@field commit_message? senpai.Config.commit_message
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
