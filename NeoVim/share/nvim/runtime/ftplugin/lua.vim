" Vim filetype plugin file.
" Language:		Lua
" Maintainer:		Doug Kearns <dougkearns@gmail.com>
" Previous Maintainer:	Max Ischenko <mfi@ukr.net>
" Contributor:		Dorai Sitaram <ds26@gte.com>
"			C.D. MacEachern <craig.daniel.maceachern@gmail.com>
"			Tyler Miller <tmillr@proton.me>
" Last Change:		2024 Jan 14

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

setlocal comments=:---,:--
setlocal commentstring=--\ %s
setlocal formatoptions-=t formatoptions+=croql

let &l:define = '\<function\|\<local\%(\s\+function\)\='

" TODO: handle init.lua
setlocal includeexpr=tr(v:fname,'.','/')
setlocal suffixesadd=.lua

let b:undo_ftplugin = "setlocal cms< com< def< fo< inex< sua<"

if exists("loaded_matchit") && !exists("b:match_words")
  let b:match_ignorecase = 0
  let b:match_words =
	\ '\<\%(do\|function\|if\)\>:' ..
	\ '\<\%(return\|else\|elseif\)\>:' ..
	\ '\<end\>,' ..
	\ '\<repeat\>:\<until\>,' ..
	\ '\%(--\)\=\[\(=*\)\[:]\1]'
  let b:undo_ftplugin ..= " | unlet! b:match_words b:match_ignorecase"
endif

if (has("gui_win32") || has("gui_gtk")) && !exists("b:browsefilter")
  let b:browsefilter = "Lua Source Files (*.lua)\t*.lua\n"
  if has("win32")
    let b:browsefilter ..= "All Files (*.*)\t*\n"
  else
    let b:browsefilter ..= "All Files (*)\t*\n"
  endif
  let b:undo_ftplugin ..= " | unlet! b:browsefilter"
endif

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: nowrap sw=2 sts=2 ts=8 noet:
