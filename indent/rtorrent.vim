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

setlocal nolisp
setlocal autoindent

setlocal indentexpr=rtorrent#indent()
setlocal indentkeys=o,O,0#,!^F,0=},0=),0=)),0=)},\

let b:undo_indent = 'setl ai< inde< indk< lisp<'
