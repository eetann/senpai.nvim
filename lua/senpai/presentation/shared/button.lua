local NuiButton = require("nui-components.button")
local n = require("nui-components")
local fn = require("nui-components.utils.fn")

local function split_and_format(str)
  local first = str:sub(1, 1)
  local rest = str:sub(2) .. " "
  return { n.line(n.text(first), rest) }
end

local Button = NuiButton:extend("Button")

function Button:init(props, popup_options)
  local processed_label = split_and_format(props.label)
  Button.super.init(
    self,
    vim.tbl_deep_extend("force", {
      lines = processed_label,
    }, props),
    vim.tbl_deep_extend("force", {
      zindex = 50,
    }, popup_options or {})
  )
end

function Button:prop_types()
  return fn.merge(Button.super.prop_types(self), {
    prepare_lines = { "function", "nil" },
  })
end

function Button:get_lines()
  local props = self:get_props()
  local lines = Button.super.get_lines(self)

  if props.prepare_lines then
    return props.prepare_lines(lines, self)
  end

  local is_focused = self:is_focused()
  local hl_group = self:hl_group(
    props.is_active and "Active" or (is_focused and "Focused" or "")
  )

  fn.ieach(lines, function(line)
    fn.ieach(line._texts, function(text, i)
      if i == 1 and not props.is_active and not is_focused then
        text.extmark = { hl_group = hl_group .. "First" }
      else
        text.extmark = { hl_group = hl_group }
      end
    end)
  end)

  return lines
end

return Button
