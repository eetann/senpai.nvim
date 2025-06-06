local M = {}

function M.execute()
  vim.api.nvim_set_hl(
    0,
    "NuiComponentsButtonFirst",
    vim.tbl_extend(
      "force",
      vim.api.nvim_get_hl(0, { name = "Comment" }),
      { bold = true, underline = true }
    )
  )
  vim.api.nvim_set_hl(0, "NuiComponentsButton", { link = "Comment" })
  vim.api.nvim_set_hl(
    0,
    "NuiComponentsButtonActive",
    { link = "@markup.heading" }
  )

  -- Tool result highlights
  vim.api.nvim_set_hl(
    0,
    "SenpaiToolResultBorder",
    vim.tbl_extend(
      "force",
      vim.api.nvim_get_hl(0, { name = "FloatBorder" }),
      { fg = "#6c7086" } -- Slightly dimmed border for tool results
    )
  )
  vim.api.nvim_set_hl(
    0,
    "SenpaiToolResultHeader",
    vim.tbl_extend(
      "force",
      vim.api.nvim_get_hl(0, { name = "Comment" }),
      { bold = true, italic = true }
    )
  )
  vim.api.nvim_set_hl(
    0,
    "SenpaiToolResultFold",
    { link = "Folded" }
  )
end

return M
