local M = {}

local function make_mention(text)
  return "`@" .. text .. "`"
end

---@param chat senpai.IChatWindow
---@param filenames string[]
local function insert2chat(chat, filenames)
  local row, col = unpack(vim.api.nvim_win_get_cursor(chat.input_area.winid))

  for _, filename in ipairs(filenames) do
    local mention = make_mention(filename)
    vim.api.nvim_buf_set_text(
      chat.input_area.bufnr,
      row - 1,
      col,
      row - 1,
      col,
      { mention .. " " }
    )
    local file_only = vim.fn.fnamemodify(filename, ":t")
    local dir_length = #filename - #file_only
    if dir_length > 0 then
      local namespace = vim.api.nvim_create_namespace("sepnai-chat")
      vim.api.nvim_buf_set_extmark(
        chat.input_area.bufnr,
        namespace,
        row - 1,
        col + 2, -- after @
        {
          end_col = col + 2 + dir_length,
          conceal = "",
        }
      )
    end

    col = col + #mention + 1
  end

  vim.api.nvim_set_current_win(chat.input_area.winid)
  vim.api.nvim_win_set_cursor(chat.input_area.winid, { row, col })
end

---@param chat senpai.IChatWindow
local function snacks(chat)
  -- local root = require("snacks.git").get_root()
  require("snacks.picker").git_files({
    untracked = true,
    cwd = vim.uv.cwd(),
    confirm = function(the_picker)
      the_picker:close()
      local files = {}
      for _, item in ipairs(the_picker:selected({ fallback = true })) do
        if item.file then
          table.insert(files, item.file)
        end
      end
      insert2chat(chat, files)
    end,
  })
end

---@param chat? senpai.IChatWindow
function M.execute(chat)
  if not chat then
    return
  end
  local ok, _ = pcall(require, "snacks.picker")
  if not ok then
    vim.notify(
      "[senpai] The following finders are currently supported\n - snacks.nvim",
      vim.log.levels.WARN
    )
  else
    snacks(chat)
  end
end

return M
