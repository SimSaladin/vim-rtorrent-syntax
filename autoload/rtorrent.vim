scriptencoding utf-8

" [ 'rtorrentPD3', 'rtorrentPD2', 'rtorrentPD', 'rtorrentStatement']
"
let s:relevant =
      \[ 'rtorrentStatement'
      \, 'rtorrentStringCommand'
      \, 'rtorrentP'
      \, 'rtorrentP2'
      \, 'rtorrentPD', 'rtorrentPD2'
      \, 'rtorrentPD3', 'rtorrentPD4'
      \, 'rtorrentFP', 'rtorrentFP2'
      \, 'rtorrentB'
      \]

function! rtorrent#get_syn_stack(line, col) abort
  let ln = type(a:line) == 0 ? a:line : line(a:line)
  let co = type(a:col) == 0 ? a:col : col([ln, a:col])
  let stack = map(synstack(ln, co), {_, x -> synIDattr(x, 'name')})
  return filter(stack, 'count(s:relevant, v:val) > 0')
endfunction

let g:myd = { }

function! rtorrent#indent(line = v:lnum) abort
  if a:line < 1
    return 0
  endif
  let prev = getline(a:line - 1)
  if prev !~# '\\\s*$'
    return 0 " Reset to 0 if previous line didn't end with line continuation.
  endif
  let ind = indent(a:line - 1)
  let prevSynStack = rtorrent#get_syn_stack(a:line - 1, '$')
  let g:myd['prevStack'] = prevSynStack
  if get(prevSynStack, 0, '') !=# 'rtorrentStatement'
    return 0 " Reset to 0 if we are not in the middle of an RC statement.
  endif
  if ind == 0
    " Always increase indent of the first continued line, because the
    " statement we are continuing began in first column.
    return &l:shiftwidth
  endif
  " Otherwise... Inspect the nesting level of two previous lines.
  let prevPrevSynStack = rtorrent#get_syn_stack(a:line - 2, '$')
  let g:myd['prevPrevStack'] = prevPrevSynStack
  let diff = prevSynStack->len() - prevPrevSynStack->len()
  let g:myd['diff'] = diff
  return max([&l:shiftwidth, ind + (&l:shiftwidth * diff)])
  "return max([0, ind + (&l:shiftwidth * diff)])
  return ind
endfunction
