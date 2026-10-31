" ==============================================================================
" Vim syntax file
" Language: rTorrent configuration language ('rtorrent')
" Original Author: Samuli Thomasson <https://github.com/SimSaladin>
" ==============================================================================

" Quit if syntax already loaded
if exists('b:current_syntax')
  finish
endif

scriptencoding utf-8

let s:cpo_save = &cpo
set cpo&vim

" Include "." in keywords
syn iskeyword @,48-57,_,.,192-255

syn keyword rtorrentTodo contained FIXME NOTE TODO XXX

" Comments                                                                {{{1

syn region rtorrentComment start=+^\s*#+me=s skip=+\n\s*#+ end=+$+ contains=@Spell,rtorrentTodo keepend fold

" Identifiers                                                             {{{1
" - Known commands
" - Variables

syn match rtorrentIdentifier       contained "\c\%(\k\|[=.-]\)\+\>" contains=rtorrentArgArgument,rtorrentDot,rtorrentKnownCmd,rtorrentIdentifierPrefix
syn match rtorrentIdentifierPrefix contained /\k\+\./me=e-1
syn match rtorrentArgArgument      contained "\<argument\.[0-3]\>"  contains=rtorrentDot
syn match rtorrentArgArgument      contained "\<\%([dpft]\|fi\)\."

syn keyword rtorrentKnownCmd contained
      \ if branch import try_import cat print do try catch not false and or
      \ execute.nothrow execute.capture_system

" Literals                                                                {{{1

" Types     "simple|string|..."
syn keyword rtorrentType          contained simple string const private value multi rlookup static nextgroup=rtorrentTypeDelim skipwhite
" Boolean   "yes|no"
syn keyword rtorrentBool          contained true yes no off on disable enable skipwhite
" Sizes     "1234M"
syn match   rtorrentSizeLit       contained "\<\d\+[TGMK]\>" skipwhite
" intervals "[dd:]hh:mm:ss"
syn match   rtorrentTimeInterval  contained "\<\%(\d\d:\)\?\d\d:\d\d:\d\d" contains=rtorrentTypeDelim skipwhite
" Numbers   "123"
syn match   rtorrentNumber        contained "\<\d\+\>" nextgroup=rtorrentTypeDelim skipwhite
" C-Char    "^Q"
syn match   rtorrentCtrlChar      contained "\^[a-zA-Z0-9]\>" skipwhite

" Strings and characters                                                 "{{{1

" StringLit: String literal ("literal")
" SStringLit: String within string "...\"inner string\""
" StringCommand: String literal is a command
" Literal: Some literal value (top-level)
" SLiteral: Some literal value (inside command string)
" Stringy: Implicit string argument

syn region  rtorrentStringLit     contained                                 start=+"+   skip=+\\"+       end=+"+     contains=rtorrentStringEscape,@Spell
syn region  rtorrentSStringLit    contained matchgroup=rtorrentSStringDelim start=+\\"+                  end=+\\"+   contains=@Spell
syn region  rtorrentStringCommand contained matchgroup=String               start=+"+   skip=+\\\\\|\\"+ end=+"+     contains=@rtorrentSRhsTop,rtorrentSStringLit,rtorrentSParens2
syn cluster rtorrentLiteral       contains=rtorrentBool,rtorrentNumber,rtorrentSizeLit,rtorrentTimeInterval,rtorrentType,rtorrentCtrlChar,rtorrentStringLit
syn cluster rtorrentSLiteral      contains=rtorrentBool,rtorrentNumber,rtorrentSizeLit,rtorrentTimeInterval,rtorrentType,rtorrentCtrlChar,rtorrentSStringLit
syn match   rtorrentStringEscape  contained '\\.'
syn match   rtorrentStringy       contained "\k.\{-}"

" Statements & methods                                                    {{{1

syn match   rtorrentMethodName    contained +\k\++ contains=rtorrentDot,rtorrentMethodNameEnd
syn match   rtorrentMethodNameEnd contained +\.\%(set_key\|set\|bind_key\)\>+ms=s+1,lc=1
syn match   rtorrentStatement               "^\s*[a-zA-Z]\k*\(\\\\\|\\\n\|.\)*$" contains=@rtorrentMethodStatement,@NoSpell    keepend fold transparent
syn match   rtorrentLhs           contained +^\k\+\>\s*=+                        contains=rtorrentMethodName,rtorrentEq        skipwhite nextgroup=rtorrentRhs
syn region  rtorrentRhs           contained start=+\_.+ skip=+\\\n+ end=+$+      contains=@rtorrentRhsTop,rtorrentParens2      skipwhite

" Values on the RHS (top-level)
syn cluster rtorrentRhsTop  contains=rtorrentDelimiter,rtorrentIdentifier,rtorrentBraces,@rtorrentLiteral,rtorrentParens1

" Values on the RHS (inside command string)
syn cluster rtorrentSRhsTop contains=rtorrentDelimiter,rtorrentIdentifier,rtorrentBraces,@rtorrentSLiteral,rtorrentSParens1

" Command specific overrides                                             "{{{2

syn cluster rtorrentMethodStatement contains=rtorrentLhs

" rtorrentMethodSchedule,rtorrentMethodInsert,rtorrentMethodInsertAs

function! s:DefineMethodSyn(key, parts) abort
  function! s:mgroup(k, x)
    return 'rtorrentMethod' . a:k . (a:x > 0 ? a:x : '')
  endfunction
  function! s:mkMatch(k, i, pat, contains, nextgroup)
    execute 'syn match '.s:mgroup(a:k, a:i).' contained '.a:pat.' contains='.a:contains.' skipwhite nextgroup='
          \ . (empty(a:nextgroup) ? s:mgroup(a:k, a:i + 1) : a:nextgroup) .' transparent'
  endfunction
  let i = 0
  for x in a:parts
    call s:mkMatch(a:key, i, x[0], x[1], x[2])
    let i = i + 1
  endfor
  execute 'syn cluster rtorrentMethodStatement add=' . s:mgroup(a:key, 0)
endfunction
function! s:methodBy(pat)
  return [ '/' . a:pat . '\s*=/', 'rtorrentMethodName,rtorrentEq', 0 ]
endfunction
function! s:param(ty, next)
  return [ '/\S.\{-}\ze,/', empty(a:ty) ? '@rtorrentRhsTop' : a:ty, a:next ]
endfunction


" "schedule = <name>, <time>, <time>, <command>"
" "method.(insert|set_key|insert.*) = ..."
call s:DefineMethodSyn('Schedule', [s:methodBy('schedule'),                     s:param('rtorrentStringy',0), s:param(0,0), s:param(0,'rtorrentCommandArgument')])
call s:DefineMethodSyn('Insert',   [s:methodBy('method\.\%(insert\|set_key\)'), s:param('rtorrentStringy',0), s:param(0,'rtorrentCommandArgument')])
call s:DefineMethodSyn('InsertAs', [s:methodBy('method\.\%(insert\.\k\+\|set\)'), s:param('rtorrentStringy','rtorrentCommandArgument')])

" New or old style command "(( ... )) or foo=bar"
syn region  rtorrentCommandArgument    contained start=+\_.+ end=+$+      contains=@rtorrentCommandArgumentTOP transparent
syn cluster rtorrentCommandArgumentTOP contains=rtorrentDelimiter,rtorrentStringCommand,rtorrentParens2

" Commands                                                               "{{{1

" Cmd list "{ ... }"
syn region rtorrentBraces              contained matchgroup=rtorrentBracesA1 start=+{+  skip=+{.\{-}}+   end=+}+ contains=@rtorrentRhsTop,rtorrentParens2     skipwhite transparent
syn region rtorrentSBraces             contained matchgroup=rtorrentBracesA1 start=+{+  skip=+{.\{-}}+   end=+}+ contains=@rtorrentSRhsTop,rtorrentSParens2   skipwhite transparent

" Cmd parens "( <cmd>[, <arg>...] )"
syn region rtorrentParens1             contained matchgroup=rtorrentParensA1 start=+(+  skip=+(.\{-})+   end=+)+ contains=@rtorrentRhsTop,rtorrentParens2     skipwhite transparent keepend
syn region rtorrentSParens1            contained matchgroup=rtorrentParensA1 start=+(+  skip=+(.\{-})+   end=+)+ contains=@rtorrentSRhsTop,rtorrentSParens2   skipwhite transparent keepend

" Cmd parens 2 "(( <command>[, <args>...] ))"
syn region rtorrentParens2             contained matchgroup=rtorrentParensB1 start=+((+ skip=+((.\{-}))+ end=+))+ contains=@rtorrentRhsTop,rtorrentParens2B   skipwhite transparent
syn region rtorrentParens2B            contained matchgroup=rtorrentParensB2 start=+((+ skip=+((.\{-}))+ end=+))+ contains=@rtorrentRhsTop,rtorrentParens2C   skipwhite transparent
syn region rtorrentParens2C            contained matchgroup=rtorrentParensB3 start=+((+ skip=+((.\{-}))+ end=+))+ contains=@rtorrentRhsTop,rtorrentParens2    skipwhite transparent
syn region rtorrentSParens2            contained matchgroup=rtorrentParensB1 start=+((+ skip=+((.\{-}))+ end=+))+ contains=@rtorrentSRhsTop,rtorrentSParens2B skipwhite transparent
syn region rtorrentSParens2B           contained matchgroup=rtorrentParensB2 start=+((+ skip=+((.\{-}))+ end=+))+ contains=@rtorrentSRhsTop,rtorrentSParens2C skipwhite transparent
syn region rtorrentSParens2C           contained matchgroup=rtorrentParensB3 start=+((+ skip=+((.\{-}))+ end=+))+ contains=@rtorrentSRhsTop,rtorrentSParens2  skipwhite transparent

" Delimiters & operators                                                 "{{{1

syn match   rtorrentTypeDelim    contained '[-|:]'
syn match   rtorrentDelimiter    contained '[,;]\|\\\n'
syn match   rtorrentDot          contained '\.'
syn match   rtorrentEq           contained '='

" Sync:                                                                   {{{1

syn sync minlines=50

" Highlights:                                                             {{{1

" Comments, etc.
hi def link rtorrentTodo             Todo
hi def link rtorrentComment          Comment
hi def link rtorrentLineComment      Comment
" Braces: single
hi def link rtorrentBracesA1         Delimiter
" Parentheses: single
hi def link rtorrentParensA1         Delimiter
" Parentheses: dual (3 levels)
hi def link rtorrentParensB1         Delimiter
hi          rtorrentParensB2         ctermfg=5
hi          rtorrentParensB3         ctermfg=13
" Literals and Constants
hi def link rtorrentBool             Boolean
hi def link rtorrentNumber           Number
hi def link rtorrentSizeLit          Constant
hi def link rtorrentTimeInterval     Constant
hi def link rtorrentCtrlChar         SpecialChar
hi def link rtorrentType             Type
" Strings and string-like
hi def link rtorrentStringLit        String
hi def link rtorrentStringy          String
hi def link rtorrentStringEscape     SpecialChar
" Inside string literals
hi def link rtorrentSStringLit       String
hi def link rtorrentSStringDelim     Underlined
" Delimiters & operators
hi def link rtorrentDelimiter        Delimiter
hi def link rtorrentTypeDelim        Operator
hi def link rtorrentEq               Operator
hi def link rtorrentDot              Operator
" Method names
hi def link rtorrentIdentifierPrefix Type
hi def link rtorrentMethodName       Keyword
hi def link rtorrentMethodNameEnd    Keyword
hi def link rtorrentKnownCmd         Keyword
hi def link rtorrentArgArgument      PreProc

" Define current syntax                                                   {{{1
let b:current_syntax = 'rtorrent'

let &cpo = s:cpo_save
unlet s:cpo_save
