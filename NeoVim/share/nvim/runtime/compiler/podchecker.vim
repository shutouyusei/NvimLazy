" Vim compiler file
" Compiler:      podchecker
" Maintainer:    vim-perl <vim-perl@googlegroups.com>
" Author:        Doug Kearns <dougkearns@gmail.com>
" Homepage:      https://github.com/vim-perl/vim-perl
" Bugs/requests: https://github.com/vim-perl/vim-perl/issues
" License:       Vim License (see :help license)
" Last Change:   2021 Oct 20
"                2024 Apr 03 by The Vim Project (removed :CompilerSet definition)

if exists("current_compiler")
  finish
endif
let current_compiler = "podchecker"

let s:cpo_save = &cpo
set cpo&vim

CompilerSet makeprg=podchecker\ -w
CompilerSet errorformat=\*\*\*\ %tRROR:\ %m\ at\ line\ %l\ in\ file\ %f,
                       \\*\*\*\ %tARNING:\ %m\ at\ line\ %l\ in\ file\ %f,
                       \%-G%.%#

let &cpo = s:cpo_save
unlet s:cpo_save
