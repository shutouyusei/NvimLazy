" Vim filetype plugin file
" Language:     fish
" Maintainer:   Nicholas Boyle (github.com/nickeb96)
" Repository:   https://github.com/nickeb96/fish.vim
" Last Change:  February 1, 2023
"               2023 Aug 28 by Vim Project (undo_ftplugin)
"               2024 May 23 by Riley Bruins <ribru17@gmail.com> ('commentstring')

if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

setlocal iskeyword=@,48-57,_,192-255,-,.
setlocal comments=:#
setlocal commentstring=#\ %s
setlocal formatoptions+=crjq

let b:undo_ftplugin = "setl cms< com< fo< isk<"
