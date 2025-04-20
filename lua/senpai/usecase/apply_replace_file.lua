local utils = require("senpai.usecase.utils")

local M = {}

---@type table<number, vim.api.keyset.get_keymap[]>
local saved_keymaps = {}

local function get_diff_hint_winbar()
  local hint = table.concat({
    "%#Constant#ga%*%#Constant#(gA)%*%#Comment#: accept(All), %*",
    "%#Constant#gr%*%#Constant#(gR)%*%#Comment#: reject(All), %*",
    "%#Constant#q%*%#Comment#: quite%*",
  }, " ")
  return "%=" .. hint .. "%="
end

local function restore_keymaps(bufnr)
  for _, key in ipairs({ "gA", "gR", "q", "ga", "gr" }) do
    vim.api.nvim_buf_del_keymap(bufnr, "n", key)
  end

  if saved_keymaps[bufnr] then
    for _, map in ipairs(saved_keymaps[bufnr]) do
      vim.keymap.set(
        map.mode,
        map.lhs,
        map.rhs or map.callback,
        { buffer = bufnr, silent = map.silent == 1, desc = map.desc }
      )
    end
    saved_keymaps[bufnr] = nil
  end
end

local function quite_diff(original_buf, ai_buf)
  restore_keymaps(original_buf)
  vim.cmd("diffoff!")
  vim.cmd("bdelete! " .. ai_buf)
end

local function set_diff_keymaps(original_buf, ai_buf, ai_win)
  saved_keymaps[original_buf] = {}
  local original_lines = vim.api.nvim_buf_get_lines(original_buf, 0, -1, false)
  local diff_lines = vim.api.nvim_buf_get_lines(ai_buf, 0, -1, false)

  ---@type {key:string,fun:function, desc:string}[]
  local kemaps = {
    {
      key = "gA",
      fun = function()
        vim.api.nvim_buf_set_lines(original_buf, 0, -1, false, diff_lines)
        quite_diff(original_buf, ai_buf)
      end,
      desc = "accept all",
    },
    {
      key = "gR",
      fun = function()
        vim.notify("reject")
        vim.api.nvim_buf_set_lines(original_buf, 0, -1, false, original_lines)
        quite_diff(original_buf, ai_buf)
      end,
      desc = "reject all",
    },
    {
      key = "q",
      fun = function()
        quite_diff(original_buf, ai_buf)
      end,
      desc = "quit diff mode",
    },
    {
      key = "ga",
      fun = function()
        local cur_buf = vim.api.nvim_get_current_buf()
        if cur_buf == original_buf then
          vim.cmd("diffget")
        else
          vim.cmd("diffput")
        end
      end,
      desc = "accept diff at cursor (AI version)",
    },
    {
      key = "gr",
      fun = function()
        local cur_buf = vim.api.nvim_get_current_buf()
        if cur_buf == original_buf then
          vim.cmd("diffput")
        else
          vim.cmd("diffget")
        end
      end,
      desc = "reject diff at cursor (original version)",
    },
  }
  for _, value in pairs(kemaps) do
    local existing = vim.api.nvim_buf_get_keymap(original_buf, "n")
    for _, map in ipairs(existing) do
      if map.lhs == value.key then
        table.insert(saved_keymaps[original_buf], map)
      end
    end
    vim.keymap.set(
      "n",
      value.key,
      value.fun,
      { buffer = original_buf, silent = true, desc = value.desc }
    )
    vim.keymap.set(
      "n",
      value.key,
      value.fun,
      { buffer = ai_buf, silent = true, desc = value.desc }
    )
  end

  local winbar_str = get_diff_hint_winbar()
  vim.api.nvim_set_option_value("winbar", winbar_str, { win = ai_win })
end

local function get_valid_replace_file_id()
  local id = utils.get_replace_file_id()
  if not id or id == "" then
    return nil
  end
  return id
end

local function get_replace_file_result(chat, id)
  local result = chat.replace_file_results[id]
  if not result then
    vim.notify("[senpai] failed to parse <replace_file>", vim.log.levels.ERROR)
    return nil
  end
  return result
end

local function save_and_restore_cursor(chat)
  local row = vim.fn.line(".", chat.log_area.winid)
  local col = vim.fn.col(".", chat.log_area.winid)
  vim.api.nvim_win_set_cursor(chat.log_area.winid, { row, col - 1 })
end

local function setup_edit_window(path)
  vim.cmd("wincmd h")
  vim.cmd("edit " .. path)
  local original_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local original_win = vim.api.nvim_get_current_win()
  local original_buf = vim.api.nvim_get_current_buf()
  local original_filetype =
    vim.api.nvim_get_option_value("filetype", { buf = original_buf })
  return original_lines, original_win, original_buf, original_filetype
end

local function find_replace_range(result)
  local range = utils.find_text(result.path, table.concat(result.search, "\n"))
  if range.start_line == 0 then
    vim.notify("[senpai]: Could not find code.", vim.log.levels.WARN)
    return nil
  end
  return range
end

local function create_ai_buffer(
  original_lines,
  range,
  result,
  id,
  original_filetype
)
  local ai_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(ai_buf, "[senpai] " .. id)
  vim.api.nvim_set_option_value(
    "filetype",
    "senpai_ai_buffer",
    { buf = ai_buf }
  )
  require("nvim-treesitter.highlight").attach(ai_buf, original_filetype)
  vim.api.nvim_buf_set_lines(ai_buf, 0, -1, false, original_lines)
  vim.api.nvim_buf_set_lines(
    ai_buf,
    range.start_line - 1,
    range.end_line - 1,
    false,
    result.replace
  )
  return ai_buf
end

local function setup_diff_windows(original_win, ai_win)
  vim.api.nvim_win_call(ai_win, function()
    vim.cmd("diffthis")
  end)
  vim.api.nvim_win_call(original_win, function()
    vim.cmd("diffthis")
  end)
  vim.api.nvim_set_current_win(original_win)
end

---@param chat senpai.IChatWindow
function M.execute(chat)
  local id = get_valid_replace_file_id()
  if not id then
    return
  end

  local result = get_replace_file_result(chat, id)
  if not result then
    return
  end

  save_and_restore_cursor(chat)
  local original_lines, original_win, original_buf, original_filetype =
    setup_edit_window(result.path)

  local range = find_replace_range(result)
  if not range then
    return
  end

  local ai_buf =
    create_ai_buffer(original_lines, range, result, id, original_filetype)
  local ai_win = vim.api.nvim_open_win(
    ai_buf,
    false,
    { vertical = true, win = original_win }
  )

  setup_diff_windows(original_win, ai_win)
  set_diff_keymaps(original_buf, ai_buf, ai_win)
end

return M
