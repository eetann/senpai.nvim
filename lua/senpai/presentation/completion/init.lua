local has_blink, blink = pcall(require, "blink.cmp")

if has_blink then
  pcall(function()
    local add_provider = blink.add_source_provider
    add_provider("senpai", {
      name = "senpai",
      module = "senpai.presentation.completion.blink",
      enabled = true,
      score_offset = 10,
    })
  end)
  pcall(function()
    blink.add_filetype_source("senpai_chat_input", "senpai")
  end)
end
