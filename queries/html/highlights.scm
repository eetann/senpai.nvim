; extends

(element
  [
   (start_tag
     (tag_name) @tag
     (#any-of? @tag "SenpaiUserInput" "SenpaiReplaceFile")
     ) @start 
   (end_tag
     (tag_name) @tag
     (#any-of? @tag "SenpaiUserInput" "SenpaiReplaceFile")
     ) @end
   ]
  (#set! conceal "")
  (#set! conceal_lines "")
  )
