local n = require("nui-components")
local Gap = require("nui-components.gap")
local Columns = require("nui-components.columns")
local Button = require("senpai.presentation.shared.button")
local IBlock = require("senpai.domain.i_block")
local utils = require("senpai.usecase.utils")

---@class senpai.DiffBlock: senpai.IDiffBlock
local M = {}
M.__index = M
setmetatable(M, { __index = IBlock })

---@param opts { winid:integer, bufnr:integer, row:integer, path:string }
---@return senpai.DiffBlock
function M.new(opts)
  local self = setmetatable({}, M)
  self.row = opts.row
  self.winid = opts.winid
  self.bufnr = opts.bufnr
  self.path = opts.path
  self.filetype = utils.get_filetype(opts.path)
  self.signal = n.create_signal({
    active_tab = "no-tab",
  })
  self.diff_text = ""
  self.replace_text = ""
  self.search_text = ""
  self:setup()

  return self
end

function M:setup_body()
  local is_tab_active = n.is_active_factory(self.signal.active_tab)
  self.body = Columns({
    flex = 1,
    children = {
      Button({
        label = "Diff",
        global_press_key = "D",
        is_active = is_tab_active("tab-diff"),
        on_press = function()
          self.signal.active_tab = "tab-diff"
          require("senpai.presentation.change_replace_tab").change_replace_tab(
            "diff",
            self.row
          )
        end,
        mappings = function()
          return {
            {
              mode = "n",
              key = "<S-Tab>",
              handler = function()
                utils.safe_set_current_win(
                  self.winid,
                  { row = self.row, col = 0 }
                )
              end,
            },
          }
        end,
      }),
      Gap({ size = 1 }, { zindex = 49 }),
      Button({
        label = "Replace",
        global_press_key = "R",
        is_active = is_tab_active("tab-replace"),
        on_press = function()
          self.signal.active_tab = "tab-replace"
          require("senpai.presentation.change_replace_tab").change_replace_tab(
            "replace",
            self.row
          )
        end,
      }),
      Gap({ size = 1 }, { zindex = 49 }),
      Button({
        label = "Search",
        global_press_key = "S",
        is_active = is_tab_active("tab-search"),
        on_press = function()
          self.signal.active_tab = "tab-search"
          require("senpai.presentation.change_replace_tab").change_replace_tab(
            "search",
            self.row
          )
        end,
      }),
      Gap({ flex = 1 }, { zindex = 49 }),
      Button({
        label = "apply",
        on_press = function()
          vim.api.nvim_set_current_win(self.winid)
          vim.api.nvim_feedkeys("a", "n", false)
        end,
        mappings = function()
          return {
            {
              mode = "n",
              key = "<Tab>",
              handler = function()
                utils.safe_set_current_win(
                  self.winid,
                  { row = self.row + 1, col = 0 }
                )
              end,
            },
          }
        end,
      }),
    },
  }, {
    zindex = 50,
  })
end

function M:setup_keymaps()
  local key_tab_list = {
    { key = "D", tab = "diff" },
    { key = "R", tab = "replace" },
    { key = "S", tab = "search" },
  }
  for _, v in ipairs(key_tab_list) do
    vim.keymap.set("n", v.key, function()
      self:change_tab(v.tab)
      require("senpai.presentation.change_replace_tab").change_replace_tab(
        v.tab,
        self.row
      )
    end, { buffer = self.bufnr })
  end
end

function M:change_tab(tab)
  if tab == "diff" then
    self.signal.active_tab = "tab-diff"
  elseif tab == "replace" then
    self.signal.active_tab = "tab-replace"
  elseif tab == "search" then
    self.signal.active_tab = "tab-search"
  end
end

-- local block = M.new({
--   winid = vim.api.nvim_get_current_win(),
--   bufnr = vim.api.nvim_get_current_buf(),
--   row = 2,
-- })
-- block:mount()
return M
