local RequestHandler = require("senpai.presentation.shared.request_handler")

local M = {}

-- TODO:pickerはokコールであったら使うようにする
-- local picker = require("snacks.picker")

---@param callback senpai.RequestHandler.callback_fun
---@return nil
function M.get_history(callback)
  RequestHandler.request({
    route = "/get-history",
    callback = callback,
  })
end

local function extract_directory_path(path)
  local dir_part = path:match("(.+)%-[0-9]+$")
  return vim.fn.fnamemodify(dir_part or path, ":~")
end

---@class senpai.history.item
---@field resourceId string "/home/ninja/workcpace-timestamp"
---@field title? string title
---@field createdAt string date "example: 2025-03-18T07:32:02.912Z"
---@field updatedAt string date example: "2025-03-18T07:32:02.912Z"
---@field metadata any I don't use it now.

---make item title for fuzzy finder
---@param history any
local function make_item_text(history)
  local text = extract_directory_path(history.id)
  if history.title then
    text = text .. ": " .. history.title
  end
  return text
end

function M.select_history()
  M.get_history(function(response)
    if response.exit ~= 0 then
      vim.notify("[senpai] failed to get history :(", vim.log.levels.ERROR)
      return
    end
    local success, histories = pcall(vim.json.decode, response.body)
    if not success then
      vim.notify("[senpai] failed to get history :(", vim.log.levels.ERROR)
      return
    end
    vim.ui.select(histories, {
      prompt = "Select History",
      format_item = make_item_text,
    }, function(choice)
      vim.print(choice)
    end)
  end)
end

return M
