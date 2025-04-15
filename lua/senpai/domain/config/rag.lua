local M = {}

---@doc.type
---@alias senpai.Config.rag.cache_strategy
---| "use_cache"
---| "no_cache"
---| "ask"

---@doc.type
---@class senpai.Config.rag
---@field cache_strategy? senpai.Config.rag.cache_strategy
---@field mode? "mention"|"auto"

-- ---@param rag_config senpai.Config.rag
-- function M.validate(rag_config)
-- end

---@type senpai.Config.rag
M.default_config = {
  cache_strategy = "ask",
  mode = "mention",
}

return M
