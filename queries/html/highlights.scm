; extends

(element
  [
   (start_tag
     (tag_name) @tag
     (#any-of? @tag "SenpaiUserInput" "SenpaiEditFile")
     ) @start 
   (end_tag
     (tag_name) @tag
     (#any-of? @tag "SenpaiUserInput" "SenpaiEditFile")
     ) @end
   ]
  (#set! conceal "")
  (#set! conceal_lines "")
  )
