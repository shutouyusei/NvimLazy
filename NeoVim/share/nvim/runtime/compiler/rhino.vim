" Vim compiler file
" Compiler:	Rhino Shell (JavaScript in Java)
" Maintainer:	Doug Kearns <dougkearns@gmail.com>
" Last Change:	2024 Apr 03

if exists("current_compiler")
  finish
endif
let current_compiler = "rhino"

let s:cpo_save = &cpo
set cpo&vim

" CompilerSet makeprg=java\ -jar\ lib/rhino-X.X.XX.jar\ -w\ -strict

CompilerSet makeprg=rhino
CompilerSet errorformat=%-Gjs:\ %.%#Compilation\ produced%.%#,
		       \%Ejs:\ \"%f\"\\,\ line\ %l:\ %m,
		       \%Ejs:\ uncaught\ JavaScript\ runtime\ exception:\ %m,
		       \%Wjs:\ warning:\ \"%f\"\\,\ line\ %l:\ %m,
		       \%Zjs:\ %p^,
		       \%Cjs:\ %.%#,
		       \%-G%.%#

let &cpo = s:cpo_save
unlet s:cpo_save
