" Vim syntax file
" Language:	Quickfix window
" Maintainer:	The Vim Project <https://github.com/vim/vim>
" Last Change:	2023 Aug 10
" Former Maintainer:	Bram Moolenaar <Bram@vim.org>

" Quit when a syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

" A bunch of useful C keywords
syn match	qfFileName	"^[^|]*" nextgroup=qfSeparator
syn match	qfSeparator	"|" nextgroup=qfLineNr contained
syn match	qfLineNr	"[^|]*" contained contains=qfError
syn match	qfError		"error" contained

" Hide file name and line number for help outline (TOC).
if has_key(w:, 'qf_toc') || get(w:, 'quickfix_title') =~# '\<TOC$'
  setlocal conceallevel=3 concealcursor=nc
  syn match	Ignore		"^[^|]*|[^|]*| " conceal
endif

" The default highlighting.
hi def link qfFileName	Directory
hi def link qfLineNr	LineNr
hi def link qfError	Error

let b:current_syntax = "qf"

" vim: ts=8
