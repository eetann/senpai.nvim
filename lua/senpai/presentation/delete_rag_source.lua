local delete_rag_source =
  require("senpai.usecase.request.rag.delete_rag_source")
local get_rag_sources = require("senpai.usecase.request.rag.get_rag_sources")
local Spinner = require("senpai.presentation.shared.spinner")

local M = {}

---@class senpai.RAG.Source
---@field source string url
---@field title string

local function call_with_spinner(source)
  local spinner = Spinner.new("[senpai] Deleting...")
  spinner:start()
  delete_rag_source.execute(source)
  spinner:stop()
end

---@param item senpai.RAG.Source
local function make_item_text(item)
  if not item.title then
    return item.source
  end
  return item.title .. " (" .. item.source .. ""
end

local function load_thread_native()
  local spinner = Spinner.new("[senpai] I'm trying to remember...")
  spinner:start()
  local sources = get_rag_sources.execute()
  spinner:stop()
  if #sources == 0 then
    vim.notify("[senpai] There is nothing in the RAG.")
    return
  end
  vim.ui.select(sources, {
    prompt = "Select the source name you wish to delete",
    format_item = make_item_text,
  }, function(item)
    if item then
      ---@cast item senpai.RAG.Source
      call_with_spinner(item.source)
    end
  end)
end

local function load_thread_snacks()
  require("snacks.picker")({
    ---@return snacks.picker.Item[]
    finder = function()
      local spinner = Spinner.new("[senpai] I'm trying to remember...")
      spinner:start()
      local sources = get_rag_sources.execute()
      spinner:stop()
      local items = {}
      local i = 1
      for _, source_item in pairs(sources) do
        ---@return snacks.picker.Item
        local item = {
          idx = i,
          score = 0,
          text = source_item.source,
          preview = { text = source_item.title, ft = "txt" },
        }
        table.insert(items, item)
        i = i + 1
      end
      return items
    end,
    ---@type snacks.picker.Action.spec
    confirm = function(the_picker, choice)
      the_picker:close()
      call_with_spinner(choice.text)
    end,
    format = "text",
    preview = "preview",
  })
end

--[=[@doc
  category = "api"
  name = "delete_rag_source"
  desc = """
```lua
senpai.delete_rag_source()
senpai.delete_rag_source(source)
```
detail -> |senpai-feature-rag|
"""

  [[args]]
  name = "source"
  type = "string?"
  desc = "If not specified, the finder will open"
--]=]
---@param source string
function M.delete_rag_source(source)
  if type(source) == "string" and source ~= "" then
    call_with_spinner(source)
    return
  end
  local ok, _ = pcall(require, "snacks.picker")
  if not ok then
    load_thread_native()
  else
    load_thread_snacks()
  end
end

return M
