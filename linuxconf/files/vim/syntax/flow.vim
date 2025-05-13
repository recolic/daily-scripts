" syntax/flow.vim

if exists("b:current_syntax")
  finish
endif

syntax clear

" Level 1 tags (0-space indent, ends with :)
syntax match FlowLevel1 /^\S.*: *$/

" Level 2 tags (2-space indent, ends with :)
syntax match FlowLevel2 /^  \S.*: *$/

" Level 3 args (4-space indent)
syntax match FlowLevel3 /^    .*$/ 

" Multi-line block: starts on a non-space line not ending with ':'
" ends just before the next level-1 or level-2 tag
syntax region FlowMultiline start=/^\S.*[^:]$/ end=/^\(\S.*: *$\|  \S.*: *$\)/me=s-1 keepend contains=NONE

" Highlight links
highlight def link FlowLevel1 Statement
highlight def link FlowLevel2 String
highlight def link FlowLevel3 Identifier
highlight FlowMultiline guifg=#888888 ctermfg=8

let b:current_syntax = "flow"

