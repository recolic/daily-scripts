" syntax/flow.vim
" Thanks GPT-4o

if exists("b:current_syntax")
  finish
endif

syntax clear

" Level 1 tags (0-space indent, ends with :)
syntax match FlowLevel1 /^\S.*: *$/

" Level 2 tags (2-space indent, ends with :)
syntax match FlowLevel2 /^  \S.*: *$/

" Multi-line block: starts on a non-space line not ending with ':'
" ends just before the next level-1 or level-2 tag
syntax region FlowMultiline start=/^\S.*[^:]$/ end=/^\(\S.*: *$\|  \S.*: *$\)/me=s-1 keepend contains=Expr

" " Level 3 args (4-space indent) (lower priority than Multiline)
" syntax match FlowLevel3 /^    .*$/ 

syntax match Expr /@{[^}]*}/

" Highlight links
highlight def link FlowLevel1 Statement
highlight def link FlowLevel2 PreProc
highlight def link FlowLevel3 Identifier
highlight def link Expr Identifier
" highlight def link FlowMultiline Comment
highlight FlowMultiline guifg=#888888 ctermfg=8

let b:current_syntax = "flow"

