local delete_rag_index = require("senpai.usecase.request.delete_rag_index")
local get_rag_index = require("senpai.usecase.request.get_rag_index")

local M = {}

---@param index_name string
---@param response senpai.RequestHandler.return
local function process_response(index_name, response)
  if response.status == "204" then
    vim.notify("[senpai] Deleted from RAG: " .. index_name, vim.log.levels.INFO)
    return
  end
  vim.notify(
    "[senpai] Deletion from RAG failed: " .. index_name,
    vim.log.levels.WARN
  )
end

local function load_thread_native()
  local indexes = get_rag_index.execute()
  vim.ui.select(indexes, {
    prompt = "Select the index name you wish to delete",
  }, function(index_name)
    delete_rag_index.execute(index_name, process_response)
  end)
end

--[=[@doc
  category = "api"
  name = "delete_rag_index"
  desc = """
```lua
senpai.delete_rag_index()
senpai.delete_rag_index(index_name)
```
detail -> |senpai-feature-rag|
"""

  [[args]]
  name = "index_name"
  type = "string?"
  desc = """
If you do not specify the id of the index_name you want to delete, the finder will open.
"""
--]=]
---@param index_name string
function M.delete_rag_index(index_name)
  if index_name then
    delete_rag_index.execute(index_name, process_response)
    return
  end
  load_thread_native()
end

return M
