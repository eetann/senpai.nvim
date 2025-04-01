# Contributing to senpai.nvim

Thank you for your interest in contributing to senpai.nvim! This document explains how you can contribute to the project.

## Set up development environment

- Neovim 0.11
- curl
- [Bun](https://bun.sh/)
- [lua-language-server](https://github.com/LuaLS/lua-language-server)
- [StyLua](https://github.com/JohnnyMorganz/StyLua)
- optional
    - [mise](https://mise.jdx.dev/): task runner
    - Docker: Used in generating `README.md` and help documentation


## structure

### Technology Stack

- UI components are written in **Lua**, while other logic is implemented in **TypeScript**
- AI-related implementations use [Mastra](https://mastra.ai/) and [Vercel AI SDK](https://sdk.vercel.ai/)

I use Bun as the npm package manager for its fast installation speed. Previously, I used Deno, but switched to Bun due to compatibility issues with Node.js file-related APIs


### Directory Structure

```txt
senpai.nvim/
├── lua/
│   └── senpai/     # Lua code for Neovim integration
├── src/            # TypeScript source code
│   └── index.ts    # Entry point for the API server
├── tests/          # Test files (lua)
├── queries/        # for Treesitter
├── doc/            # document
└── scripts/        # for document generation and testing
```


### AI Implementation
AI-related logic is implemented as an API using the framework [Hono](https://hono.dev/)

You can start the API server by itself by executing the following command.
```sh
bun run src/index.ts --port 9942
```
If you are using [mise](https://mise.jdx.dev/), you can start `mise run dev-server`.

**Known issue**: The following warning may appear in the log.

```txt
llamaindex was already imported. This breaks constructor checks and will lead to issues!
```
This doesn't affect functionality and can be ignored. For more details, see [Issue #2861 · mastra-ai/mastra](https://github.com/mastra-ai/mastra/issues/2861).

Access `http://localhost:9942/doc` to view the Swagger UI, which shows arguments and responses. You can also execute API calls using the `Try it out` button!

<img width="600" alt="SwaggerUI" src="https://github.com/user-attachments/assets/72a095a2-b360-4a4c-a53e-f7c3afe9e9ed" />


### Testing
I use [mini.test](https://github.com/echasnovski/mini.nvim/blob/main/TESTING.md) for testing.

If you are using [mise](https://mise.jdx.dev/), you can use the following command to watch to run the test.
```sh
mise watch test
```

If you do not use mise, execute the command written in `run` of `tasks.test` in mise.toml directly.


#### Minimum Configuration
Minimum configuration is `./scripts/test/minimal_init.lua`.

It can be started with the following command.
```sh
nvim --noplugin -u ./scripts/test/minimal_init.lua
```

If you are using mise, you can start it with the following command.
- `mise run launch`: launch
- `mise run launch-tmux`: launch in tmux pane


### Generate Documents
Generate documents with the following flow.

1. prepare a Docker container with `mise run prepare-generate-doc` (only the first time)
2. write documentation in lua comments as TOML format or [Lua Language Server annotations](https://luals.github.io/wiki/annotations/)
3. write documentation in README
4. update `README.md` and `doc/senpai.txt` with `mise run generate-doc`,

```txt
scripts/doc
├── generate.ts       # Edit README from commented out lua
└── minimal_init.lua  # minimum init.lua
```

This approach was based on [nvim-deck](https://github.com/hrsh7th/nvim-deck).

By using `generate.ts`, \
the specified comment in `README.md` `<! -- auto-generate-s:foo -->` to `<! -- auto-generate-e:foo -->` will be \
replaced with the contents of TOML and annotations.


#### TOML comment

##### API example
```lua
--[=[@doc
  category = "api"
  name = "regist_url_at_rag"
  desc = """
\`\`\`lua
senpai.regist_url_at_rag()
senpai.regist_url_at_rag(url)
\`\`\`
Fetch URL and save to RAG.
Cache control can be configured in \|senpai.Config.rag.cache_strategy\|.
"""

  [[args]]
  name = "url"
  type = "string|nil"
  desc = "URL. If not specified, the input UI will open"

  [[args]]
  name = "no_cache"
  type = "boolean|nil"
  desc = "If set to true, no cache is used regardless of Config."
--]=]
```


##### Type example
```lua
---@doc.type
---@alias senpai.Config.rag.cache_strategy
---| "use_cache"
---| "no_cache"
---| "ask"
```


##### Command exmaple
```lua
--[=[@doc
category = "command"
name = "commitMessage"
desc = "detail -> |senpai-api-write_commit_message|"

[[args]]
name = "language"
desc = "language"
--]=]
```


## Development Workflow

1. Fork this repository
2. Create a branch for feature development or bug fixes
3. Implement your changes
4. Run tests
5. Create a pull request

[StyLua](https://github.com/JohnnyMorganz/StyLua) for Lua and [Biome](https://biomejs.dev/) for TypeScript to format. Biome is installed in `package.json`.
