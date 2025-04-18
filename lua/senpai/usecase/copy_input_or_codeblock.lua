local M = {}

---@return "SenpaiUserInput"|"SenpaiReplaceFile"|nil
---@return string
local function get_senpai_tag_at_cursor()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1 -- 0-indexed
  local col = cursor[2]

  local ok, _ = pcall(require, "nvim-treesitter.ts_utils")
  if not ok then
    vim.notify("[senpai] nvim-treesitter not found.")
    return nil, ""
  end

  local lang = "html"
  local parser = vim.treesitter.get_parser(0, lang)
  if not parser then
    return nil, ""
  end
  local tree = parser:parse()[1]
  local root = tree:root()

  local node = root:named_descendant_for_range(row, col, row, col)
  if not node then
    return nil, ""
  end

  while node do
    if node:type() == "element" then
      local text = vim.treesitter.get_node_text(node, 0)
      if text:find("<SenpaiUserInput>") then
        return "SenpaiUserInput", text
      elseif text:find("SenpaiReplaceFile") then
        return "SenpaiReplaceFile", text
      end
    end
    node = node:parent()
  end

  return nil, ""
end

---@param chat senpai.IChatWindow
function M.execute(chat)
  local tag, text = get_senpai_tag_at_cursor()
  if tag == "SenpaiUserInput" then
    local captured = text:match("<SenpaiUserInput>%s*(.-)%s*</SenpaiUserInput>")
    vim.fn.setreg("+", captured or "")
    vim.notify("[senpai] yank user prompt", vim.log.levels.INFO)
  elseif tag == "SenpaiReplaceFile" then
    local id = text:match('<SenpaiReplaceFile%s+id="(.-)"')
    if not id or id == "" then
      return
    end
    local result = chat.replace_file_results[id]
    if not result then
      vim.notify(
        "[senpai] failed to parse <replace_file>",
        vim.log.levels.ERROR
      )
      return
    end
    vim.fn.setreg("+", result.replace or "")
    vim.notify("[senpai] yank current code", vim.log.levels.INFO)
  end
end

return M
