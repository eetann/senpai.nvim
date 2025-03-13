; extends

(element
  [
   (start_tag
      (tag_name) @tag
      (#eq? @tag "SenpaiUserInput")
      ) @start 
   (end_tag
     (tag_name) @tag
     (#eq? @tag "SenpaiUserInput")
     ) @end
   ]
  (#set! conceal "")
  (#set! conceal_lines "")
  )
