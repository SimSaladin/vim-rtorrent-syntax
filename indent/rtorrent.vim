" ==============================================================================
" Vim indent file
" Language: rTorrent configuration language ('rtorrent')
" Original Author: Samuli Thomasson <https://github.com/SimSaladin>
" ==============================================================================

if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

scriptencoding utf-8

setl indentexpr=rtorrent#indent()
