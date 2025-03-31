local delete_rag_source =
  require("senpai.usecase.request.rag.delete_rag_source")
local get_rag_sources = require("senpai.usecase.request.rag.get_rag_sources")
local Spinner = require("senpai.presentation.shared.spinner")

local M = {}

---@class senpai.RAG.Source
---@field source string url
---@field title string

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
      delete_rag_source.execute(item.source)
    end
  end)
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
  desc = """
If you do not specify the id of the source you want to delete, the finder will open.
"""
--]=]
---@param source string
function M.delete_rag_source(source)
  if source and source ~= "" then
    delete_rag_source.execute(source)
    return
  end
  load_thread_native()
end

return M
