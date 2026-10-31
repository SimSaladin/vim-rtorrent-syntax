scriptencoding utf-8

let s:relevant =
      \[ 'rtorrentStatement'
      \, 'rtorrentStringCommand'
      \, 'rtorrentParens1'
      \, 'rtorrentParens2'
      \, 'rtorrentSParens1'
      \, 'rtorrentSParens2'
      \, 'rtorrentBraces'
      \]

function! s:getsyns(line, col) abort
  let stack = map(synstack(a:line, a:col), {_, x -> synIDattr(x, 'name')})
  return reverse(filter(stack, 'count(s:relevant, v:val) > 0'))
endfunction

function! rtorrent#indent(line = v:lnum) abort
  let prev_line = getline(a:line - 1)
  if a:line > 1 && prev_line =~# '\\\s*$'
    let i = indent(a:line - 1)
    if i == 0
      let i += &l:shiftwidth * 2
    else
      let stack = s:getsyns(a:line-1, col([a:line-1, '$'])-1)
      let g:last_stack = stack
      if count(stack, 'rtorrentStatement') <= 0
        return 0
      endif
      for it in stack
        if it =~# 'rtorrentS\?Parens2' && prev_line =~# '(\s\{-}(\%(.\%()\s\{-})\)\@!\)\{-}$'
          let i += &l:shiftwidth
          break
        elseif it =~# 'rtorrentBraces' && prev_line =~# '{\%([^}]\)\{-}$'
          let i += &l:shiftwidth
          break
        elseif it =~# 'rtorrentStringCommand'
          let [bl, bc] = searchpos('^\s*\S\zs', 'bn', a:line-1, 0, 'line(".")>=' . a:line)
          let bstack = s:getsyns(bl,bc)
          if count(bstack, 'rtorrentStringCommand') < count(stack, 'rtorrentStringCommand')
            let i += &l:shiftwidth
            break
          elseif bstack->len() > stack->len()
            let i -= &l:shiftwidth
          endif
        endif
      endfor
    endif
    return i
  elseif count(s:getsyns(a:line-1, col([a:line-1, '$'])), 'rtorrentStatement') >= 1
    return 0
  endif

endfunction
