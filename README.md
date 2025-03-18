# senpai.nvim
Senpai is super reliable Neovim AI plugin!


## Feature
### Chat
You can chat with AI.
If you write the file name, it will automatically read it.
If you write `foo/bar/buz.txt` as `summarize buz.txt`,
it will be recognized.
(internally it searches `**/buz.txt` for files under git control).

### default Config
<!-- auto-generate-s:default_config -->
```lua
{
  commit_message = {
    language = "English"
  },
  provider = "openai",
  providers = {
    anthropic = {
      model = "claude-3-7-sonnet-20250219"
    },
    openai = {
      model = "gpt-4o"
    },
    openrouter = {
      model = "anthropic/claude-3.7-sonnet"
    }
  }
}
```
<!-- auto-generate-e:default_config -->

## API
<!-- auto-generate-s:api -->


<!-- panvimdoc-include-comment senpai.generate_commit_message(language) ~ -->

<!-- panvimdoc-ignore-start -->
### senpai.generate_commit_message(language)
<!-- panvimdoc-ignore-end -->

AI generate conventional commit message of commitizen convention format.


| Name | Type | Description |
|------|------|-------------|
| language | string | Language of commit message |
| callback | senpai.RequestHandler.callback | Function to be processed using the response |

&nbsp;



<!-- panvimdoc-include-comment senpai.setup(config) ~ -->

<!-- panvimdoc-ignore-start -->
### senpai.setup(config)
<!-- panvimdoc-ignore-end -->

Setup senpai


| Name | Type | Description |
|------|------|-------------|
| config | senpai.Config | Setup senpai |

&nbsp;



<!-- panvimdoc-include-comment senpai.toggle_chat() ~ -->

<!-- panvimdoc-ignore-start -->
### senpai.toggle_chat()
<!-- panvimdoc-ignore-end -->

Toggle chat.

_No arguments_
&nbsp;



<!-- panvimdoc-include-comment senpai.write_commit_message(language) ~ -->

<!-- panvimdoc-ignore-start -->
### senpai.write_commit_message(language)
<!-- panvimdoc-ignore-end -->

AI write conventional commit message of commitizen convention format.


| Name | Type | Description |
|------|------|-------------|
| language | string | Language of commit message |

&nbsp;

<!-- auto-generate-e:api -->
## Commands
`:Senpai {subcommand}`
<!-- auto-generate-e:command -->
<!-- auto-generate-s:command -->


<!-- panvimdoc-include-comment commitMessage ~ -->

<!-- panvimdoc-ignore-start -->
### :Senpai commitMessage
<!-- panvimdoc-ignore-end -->

detail -> |senpai.write_commit_message|


| Name | Description |
|------|-------------|
| language | language |

&nbsp;



<!-- panvimdoc-include-comment toggleChat ~ -->

<!-- panvimdoc-ignore-start -->
### :Senpai toggleChat
<!-- panvimdoc-ignore-end -->

|senpai-chat|

_No arguments_
&nbsp;

<!-- auto-generate-e:command -->
<!-- auto-generate-s:command -->


<!-- panvimdoc-include-comment commitMessage ~ -->

<!-- panvimdoc-ignore-start -->
### :Senpai commitMessage
<!-- panvimdoc-ignore-end -->

detail -> |senpai.write_commit_message|


| Name | Description |
|------|-------------|
| language | language |

&nbsp;



<!-- panvimdoc-include-comment toggleChat ~ -->

<!-- panvimdoc-ignore-start -->
### :Senpai toggleChat
<!-- panvimdoc-ignore-end -->

|senpai-chat|

_No arguments_
&nbsp;

<!-- auto-generate-e:command -->
<!-- auto-generate-s:command -->


<!-- panvimdoc-include-comment commitMessage ~ -->

<!-- panvimdoc-ignore-start -->
### :Senpai commitMessage
<!-- panvimdoc-ignore-end -->

detail -> |senpai.write_commit_message|


| Name | Description |
|------|-------------|
| language | language |

&nbsp;



<!-- panvimdoc-include-comment toggleChat ~ -->

<!-- panvimdoc-ignore-start -->
### :Senpai toggleChat
<!-- panvimdoc-ignore-end -->

|senpai-chat|

_No arguments_
&nbsp;

<!-- auto-generate-e:command -->
<!-- auto-generate-s:command -->


<!-- panvimdoc-include-comment commitMessage ~ -->

<!-- panvimdoc-ignore-start -->
### :Senpai commitMessage
<!-- panvimdoc-ignore-end -->

detail -> |senpai.write_commit_message|


| Name | Description |
|------|-------------|
| language | language |

&nbsp;

<!-- auto-generate-e:command -->
<!-- auto-generate-s:command -->

## Type
<!-- auto-generate-s:type -->

```vimdoc
*senpai.Config*
```
```lua
---@class senpai.Config
---@field provider? provider
---@field providers? table<string, senpai.Config.providers.Provider>
---@field commit_message? senpai.Config.commit_message
```


```vimdoc
*senpai.Config.commit_message*
```
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


```vimdoc
*senpai.Config.providers.AnthropicProvider*
```
```lua
---@class senpai.Config.providers.AnthropicProvider
---@field model ("claude-3-7-sonnet-20250219" | "claude-3-5-sonnet-20241022")
```


```vimdoc
*senpai.Config.providers.OpenAIProvider*
```
```lua
---@class senpai.Config.providers.OpenAIProvider
---@field model ("gpt-4o" | "gpt-4o-mini")
```


```vimdoc
*senpai.Config.providers.OpenRouterProvider*
```
```lua
---@class senpai.Config.providers.OpenRouterProvider
---@field model string
---   You can get a list of models with the following command.
---   >sh
---   curl https://openrouter.ai/api/v1/models | jq '.data[].id'
---   # check specific model
---   curl https://openrouter.ai/api/v1/models | \
---     jq '.data[] | select(.id == "deepseek/deepseek-r1:free") | .'
--- <
```


```vimdoc
*senpai.Config.providers.Provider*
```
```lua
---@class senpai.Config.providers.Provider
---@field model string
```

<!-- auto-generate-e:type -->
