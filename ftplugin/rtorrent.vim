" ==============================================================================
" Vim ftplugin file
" Language: rTorrent configuration language ('rtorrent')
" Original Author: Samuli Thomasson <https://github.com/SimSaladin>
" ==============================================================================

if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

if !exists('b:undo_ftplugin')
  let b:undo_ftplugin = ''
endif

setlocal comments=:#
setlocal commentstring=#\ %s
setlocal iskeyword+=.
setlocal foldmethod=syntax
setlocal expandtab
setlocal shiftwidth=2

let b:undo_ftplugin .= 'setlocal comments< commentstring< iskeyword< foldmethod< expandtab< shiftwidth< |'

let &cpo = s:cpo_save
unlet s:cpo_save
