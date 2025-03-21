" This Vim script deletes all the menus, so that they can be redefined.
" Warning: This also deletes all menus defined by the user!
"
" Maintainer:	The Vim Project <https://github.com/vim/vim>
" Last Change:	2023 Aug 10
" Former Maintainer:	Bram Moolenaar <Bram@vim.org>

aunmenu *
tlunmenu *

if exists('#SetupLazyloadMenus')
  au! SetupLazyloadMenus
  augroup! SetupLazyloadMenus
endif

if exists('#buffer_list')
  au! buffer_list
  augroup! buffer_list
endif

if exists('#LoadBufferMenu')
  au! LoadBufferMenu
  augroup! LoadBufferMenu
endif

if exists('#spellmenu')
  au! spellmenu
  augroup! spellmenu
endif

if exists('#SpellPopupMenu')
  au! SpellPopupMenu
  augroup! SpellPopupMenu
endif

unlet! g:did_install_default_menus
unlet! g:did_install_syntax_menu

if exists('g:did_menu_trans')
  menutrans clear
  unlet g:did_menu_trans
endif

unlet! g:find_help_dialog

unlet! g:menutrans_fileformat_choices
unlet! g:menutrans_fileformat_dialog
unlet! g:menutrans_help_dialog
unlet! g:menutrans_no_file
unlet! g:menutrans_path_dialog
unlet! g:menutrans_set_lang_to
unlet! g:menutrans_spell_add_ARG_to_word_list
unlet! g:menutrans_spell_change_ARG_to
unlet! g:menutrans_spell_ignore_ARG
unlet! g:menutrans_tags_dialog
unlet! g:menutrans_textwidth_dialog

" vim: set sw=2 :
