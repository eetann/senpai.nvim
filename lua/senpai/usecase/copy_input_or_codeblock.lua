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
    return
  end

  local manager = chat.sticky_popup_manager
  if not manager then
    return
  end

  local row = manager:find_prev_popup_row()
  if not row then
    return
  end

  local diff_block = manager.popups[row]
  if not diff_block then
    return
  end
  local active_tab = diff_block.signal.active_tab:get_value()
  if active_tab == "tab-diff" then
    vim.fn.setreg("+", diff_block.diff_text or "")
  elseif active_tab == "tab-replace" then
    vim.fn.setreg("+", diff_block.replace_text or "")
  else
    vim.fn.setreg("+", diff_block.search_text or "")
  end
  vim.notify("[senpai] yank current code", vim.log.levels.INFO)
end

return M
