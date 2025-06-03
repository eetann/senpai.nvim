local utils = require("senpai.usecase.utils")
local send_text = require("senpai.usecase.send_text")

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
  local group_name = "SenpaiDiffKeymaps_" .. bufnr
  pcall(vim.api.nvim_del_augroup_by_name, group_name)

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

  local group_name = "SenpaiDiffKeymaps_" .. original_buf
  vim.api.nvim_create_augroup(group_name, { clear = true })
  vim.api.nvim_create_autocmd({ "BufDelete", "BufHidden" }, {
    group = group_name,
    once = true,
    buffer = ai_buf,
    callback = function()
      if saved_keymaps[original_buf] then
        restore_keymaps(original_buf)
      end
    end,
  })
end

local function edit_or_switch(file)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      if name == vim.fn.fnamemodify(file, ":p") then
        vim.api.nvim_set_current_buf(buf)
        return
      end
    end
  end
  vim.cmd("edit " .. vim.fn.fnameescape(file))
end

local function setup_edit_window(path)
  return original_win, original_buf, original_filetype
end

---@param original_buf integer
---@param diff_block senpai.IDiffBlock
---@param filetype string
---@return {bufnr:integer, errors: string}
local function create_ai_buffer(original_buf, diff_block, filetype)
  return { bufnr = ai_buf, errors = errors }
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

---@param diff_block senpai.IDiffBlock
function M.execute(diff_block)
  vim.cmd("wincmd h")
  edit_or_switch(diff_block.path)
  local original_bufnr = vim.api.nvim_get_current_buf()
  local filetype =
    vim.api.nvim_get_option_value("filetype", { buf = original_bufnr })

  local ai_bufnr = vim.api.nvim_create_buf(false, true)
  local id = utils.create_random_id(20)
  vim.api.nvim_buf_set_name(ai_bufnr, "[senpai] " .. id)
  vim.api.nvim_set_option_value(
    "filetype",
    "senpai_ai_buffer",
    { buf = ai_bufnr }
  )
  local ok, _ =
    pcall(require("nvim-treesitter.highlight").attach, ai_bufnr, filetype)
  if not ok then
    vim.api.nvim_set_option_value("syntax", filetype, { buf = ai_bufnr })
  end

  local original_lines =
    vim.api.nvim_buf_get_lines(original_bufnr, 0, -1, false)
  vim.api.nvim_buf_set_lines(ai_bufnr, 0, -1, false, original_lines)
  local errors = ""
  for _, diff in ipairs(diff_block.diffs) do
    local range = utils.find_text(diff_block.path, diff.search)
    if range.start_line == 0 then
      errors = errors
        .. string.format(
          [[
The SEARCH block:
```
%s
```
does not match anything in the file or was searched out of order in the provided blocks.
]],
          diff.search
        )
      goto continue
    end
    vim.api.nvim_buf_set_lines(
      ai_bufnr,
      range.start_line - 1,
      range.end_line - 1,
      false,
      vim.split(diff.replace, "\n")
    )
    ::continue::
  end
  if errors ~= "" then
    errors = "[replace_inf_file] \n" .. errors
  end
  return {
    original_bufnr = original_bufnr,
    ai_bufnr = ai_bufnr,
    errors = errors,
  }
end

return M
