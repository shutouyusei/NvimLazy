" Vim compiler file
" Compiler:	SML/NJ Compiler
" Maintainer:	Doug Kearns <dougkearns@gmail.com>
" Last Change:	2024 Apr 03

if exists("current_compiler")
  finish
endif
let current_compiler = "sml"

let s:cpo_save = &cpo
set cpo&vim

CompilerSet makeprg=sml
CompilerSet errorformat=%f:%l.%c-%e.%k\ %trror:\ %m,
		       \%f:%l.%c\ %trror:\ %m,
		       \%trror:\ %m,
		       \%f:%l.%c-%e.%k\ %tarning:\ %m,
		       \%f:%l.%c\ %tarning:\ %m,
		       \%tarning:\ %m,
		       \%-G%.%#

let &cpo = s:cpo_save
unlet s:cpo_save
