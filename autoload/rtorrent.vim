scriptencoding utf-8

function! rtorrent#get_syn_stack(line, col) abort
  let ln = type(a:line) == 0 ? a:line : line(a:line)
  let co = type(a:col) == 0 ? a:col : col([ln, a:col])
  let stack = map(synstack(ln, co), {_, x -> synIDattr(x, 'name')})
  return filter(stack, {_, x ->
        \ x =~# '^rtorrent\(Statement\|StringCommand\|[PBF][PD]\?[2-9]\?\)$' })
endfunction

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
  if get(prevSynStack, 0, '') !=# 'rtorrentStatement'
    return 0 " Reset to 0 if we are not in the middle of an RC statement.
  endif
  if ind == 0
    " Always increase indent of the first continued line, because the
    " statement we are continuing began in first column.
    return &l:shiftwidth
  endif
  " Add to indent the previous line nesting difference
  let synStack0 = rtorrent#get_syn_stack(a:line - 1, 1)
  let synStackEnd = rtorrent#get_syn_stack(a:line - 1, '$')
  let diff = synStackEnd->len() - synStack0->len()
  let ind += diff * &l:shiftwidth
  " If this line seems to decrease indentation, decrease indentation
  let cur = getline(a:line)
  if cur =~# '^\s*[)}]'
    let synStack0 = rtorrent#get_syn_stack(a:line, 1)
    let synStackEnd = rtorrent#get_syn_stack(a:line, '$')
    let diff = synStackEnd->len() - synStack0->len()
    let ind += diff * &l:shiftwidth
  endif
  return max([&l:shiftwidth, ind])
endfunction
