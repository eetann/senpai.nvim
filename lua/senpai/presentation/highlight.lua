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
end

return M
