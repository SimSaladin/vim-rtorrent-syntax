scriptencoding utf-8

if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

setl indentexpr=rtorrent#indent()
