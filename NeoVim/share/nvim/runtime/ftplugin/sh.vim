" Vim filetype plugin file
" Language:		sh
" Maintainer:		Doug Kearns <dougkearns@gmail.com>
" Previous Maintainer:	Dan Sharp
" Contributor:		Enno Nagel <ennonagel+vim@gmail.com>
"			Eisuke Kawashima
" Last Change:		2024 Sep 19 by Vim Project (compiler shellcheck)

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let s:save_cpo = &cpo
set cpo-=C

setlocal comments=b:#
setlocal commentstring=#\ %s
setlocal formatoptions-=t formatoptions+=croql

let b:undo_ftplugin = "setl com< cms< fo<"

" Shell:  thanks to Johannes Zellner
if exists("loaded_matchit") && !exists("b:match_words")
  let b:match_ignorecase = 0
  let s:sol = '\%(;\s*\|^\s*\)\@<='  " start of line
  let b:match_words =
	\  s:sol .. 'if\>:' .. s:sol.'elif\>:' .. s:sol.'else\>:' .. s:sol .. 'fi\>,' ..
	\  s:sol .. '\%(for\|while\)\>:' .. s:sol .. 'done\>,' ..
	\  s:sol .. 'case\>:' .. s:sol .. 'esac\>'
  unlet s:sol
  let b:undo_ftplugin ..= " | unlet! b:match_ignorecase b:match_words"
endif

if (has("gui_win32") || has("gui_gtk")) && !exists("b:browsefilter")
  let  b:browsefilter = "Bourne Shell Scripts (*.sh)\t*.sh\n" ..
	\		"Korn Shell Scripts (*.ksh)\t*.ksh\n" ..
	\		"Bash Shell Scripts (*.bash)\t*.bash\n"
  if has("win32")
    let b:browsefilter ..= "All Files (*.*)\t*\n"
  else
    let b:browsefilter ..= "All Files (*)\t*\n"
  endif
  let b:undo_ftplugin ..= " | unlet! b:browsefilter"
endif

if get(b:, "is_bash", 0)
  if exists(':terminal') == 2
    command! -buffer -nargs=1 ShKeywordPrg silent exe ':term bash -c "help "<args>" 2>/dev/null || man "<args>""'
  else
    command! -buffer -nargs=1 ShKeywordPrg echo system('bash -c "help <args>" 2>/dev/null || MANPAGER= man "<args>"')
  endif
  setlocal keywordprg=:ShKeywordPrg
  let b:undo_ftplugin ..= " | setl kp< | sil! delc -buffer ShKeywordPrg"

  if !exists('current_compiler')
    compiler shellcheck
  endif
  let b:undo_ftplugin .= ' | compiler make'
endif

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: nowrap sw=2 sts=2 ts=8 noet:
