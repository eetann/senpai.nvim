; extends

((element
   (start_tag
      (tag_name) @tag
      (#eq? @tag "SenpaiUserInput")))
  @markup.heading (#set! conceal_lines ""))

((element (end_tag (tag_name) @tag (#eq? @tag "SenpaiUserInput")))
  @markup.heading (#set! conceal_lines ""))
