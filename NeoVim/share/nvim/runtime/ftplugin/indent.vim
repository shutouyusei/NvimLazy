" Vim filetype plugin file
" Language:		indent(1) configuration file
" Maintainer:		Doug Kearns <dougkearns@gmail.com>
" Previous Maintainer:	Nikolai Weibull <now@bitwi.se>
" Latest Revision:	2008-07-09
"			2024-06-02 by Riley Bruins <ribru17@gmail.com> ('commentstring')

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

let b:undo_ftplugin = "setl com< cms< fo<"

setlocal comments=s1:/*,mb:*,ex:*/ commentstring=/*\ %s\ */
setlocal formatoptions-=t formatoptions+=croql

let &cpo = s:cpo_save
unlet s:cpo_save
