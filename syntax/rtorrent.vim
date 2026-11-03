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

function! s:mkNestedParens(nameBase, matchGroupBase, match, containsBase, limit)"{{{
  let depth = 1
  while depth <= a:limit
    execute 'syn region ' . a:nameBase . (depth==1?'':depth)
          \ . ' contained matchgroup=' . a:matchGroupBase . depth . ' ' . a:match
          \ . ' contains=' . a:containsBase . ',' . a:nameBase . (depth+1 > a:limit ? '' : depth+1)
          \ . ' skipwhite'
          \ . ' fold'
    "     \ . ' transparent'
    let depth += 1
  endwhile
endfunction"}}}

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
syn region  rtorrentStringCommand contained matchgroup=String               start=+"+   skip=+\\\\\|\\"+ end=+"+     contains=@rtorrentSRhsTop,rtorrentSStringLit,rtorrentSPD keepend
syn cluster rtorrentLiteral       contains=rtorrentBool,rtorrentNumber,rtorrentSizeLit,rtorrentTimeInterval,rtorrentType,rtorrentCtrlChar,rtorrentStringLit
syn cluster rtorrentSLiteral      contains=rtorrentBool,rtorrentNumber,rtorrentSizeLit,rtorrentTimeInterval,rtorrentType,rtorrentCtrlChar,rtorrentSStringLit
syn match   rtorrentStringEscape  contained '\\.'
syn match   rtorrentStringy       contained "\S.\{-}"
syn region  rtorrentStringy       contained                                 start=+"+   skip=+\\"+       end=+"+     contains=rtorrentStringEscape,@Spell

" Statements & methods                                                    {{{1

syn match   rtorrentMethodName    contained +\k\++ contains=rtorrentDot,rtorrentMethodNameEnd
syn match   rtorrentMethodNameEnd contained +\.\%(set_key\|set\|bind_key\)\>+ms=s+1,lc=1
syn match   rtorrentStatement               "^\s*[a-zA-Z]\k*\(\\\\\|\\\n\|.\)*$" contains=@rtorrentMethodStatement,@NoSpell    keepend fold transparent
syn match   rtorrentLhs           contained +^\k\+\>\s*=+                        contains=rtorrentMethodName,rtorrentEq        skipwhite nextgroup=rtorrentRhs
syn region  rtorrentRhs           contained start=+\_.+ skip=+\\\n+ end=+$+      contains=@rtorrentRhsTop,rtorrentPD      skipwhite

" Values on the RHS (top-level)
syn cluster rtorrentRhsTop  contains=rtorrentDelimiter,rtorrentIdentifier,@rtorrentLiteral,rtorrentB,rtorrentP

" Values on the RHS (inside command string)
syn cluster rtorrentSRhsTop contains=rtorrentDelimiter,rtorrentIdentifier,@rtorrentSLiteral,rtorrentSB,rtorrentSP

" Command specific overrides                                             "{{{2

syn cluster rtorrentMethodStatement contains=rtorrentLhs

" "schedule = <name>, <time>, <time>, <command>"
" "method.(insert|set_key|insert.*) = ..."
" "if = <cond>, <then>, <elif_else>"
" "branch = <cond>, <then>, <elif_else>"

function! s:DefStatement(key, pat, args) abort"{{{
  function! s:mgroup(k, x)
    return 'rtorrentStmt' . a:k . (a:x > 0 ? a:x : '')
  endfunction
  function! s:mkMatch(k, i, pat, contains, nextgroup)
    execute 'syn match '.s:mgroup(a:k, a:i).' contained '.a:pat.' contains='.a:contains.' skipwhite nextgroup='
          \ . (empty(a:nextgroup) ? s:mgroup(a:k, a:i + 1) : a:nextgroup) .' transparent'
  endfunction
  call s:mkMatch(a:key, 0, '/\%(' . a:pat . '\)\s*=/', 'rtorrentMethodName,rtorrentEq', s:mgroup(a:key, 1))
  call s:mkMatch(a:key . 'I', 0, '/\%(' . a:pat . '\)\s*,/', 'rtorrentMethodName,rtorrentDelimiter', s:mgroup(a:key, 1))
  let i = 1
  for x in a:args
    let contains = x
    let nextgroup = (i + 1 >= len(a:args)) ? a:args[-1] : s:mgroup(a:key, i + 1)
    execute 'syn region ' . s:mgroup(a:key, i) . ' contained start=/\S/ matchgroup=rtorrentDelimiter end=/,\s*\%(\\\n\s*\)\?/ contains='.contains.' skipwhite'
          \ . ' nextgroup=' . nextgroup .' transparent'
    let i = i + 1
  endfor
  execute 'syn cluster rtorrentMethodStatement add=' . s:mgroup(a:key, 0)
  execute 'syn cluster rtorrentMethodCall add=' . s:mgroup(a:key . 'I', 0)
endfunction"}}}

call s:DefStatement('Schedule', 'schedule', ['rtorrentStringy', '@rtorrentRhsTop', '@rtorrentRhsTop', '@rtorrentCommandArgumentTOP'])
call s:DefStatement('MethodInsert', 'method\.insert', ['rtorrentStringy', 'rtorrentType', '@rtorrentCommandArgumentTOP'])
call s:DefStatement('MethodSet', 'method\.set', ['rtorrentStringy', '@rtorrentCommandArgumentTOP'])
call s:DefStatement('MethodSetKey', 'method\.set_key', ['rtorrentStringy', 'rtorrentStringy', '@rtorrentCommandArgumentTOP'])
call s:DefStatement('MethodInsertSimple', 'method\.insert\.\%(simple\|c_simple\|s_c_simple\)', ['rtorrentStringy','@rtorrentCommandArgumentTOP'])
call s:DefStatement('MethodInsertValue', 'method\.insert\.value', ['rtorrentStringy','@rtorrentRhsTop'])
call s:DefStatement('Keyword1',       'catch\|try\|print\|not', ['@rtorrentCommandArgumentTOP'])
call s:DefStatement('Keyword2',       'if\|branch', ['@rtorrentCommandArgumentTOP', '@rtorrentCommandArgumentTOP', '@rtorrentCommandArgumentTOP'])
call s:DefStatement('View',  'view\.\%(filter\|sort\.current\|sort\.new\)', ['rtorrentStringy', '@rtorrentCommandArgumentTOP'])

" New or old style command "(( ... )) or foo=bar"
syn region  rtorrentCommandArgument    contained start=+\_.+ end=+$+      contains=@rtorrentCommandArgumentTOP transparent
syn cluster rtorrentCommandArgumentTOP contains=rtorrentDelimiter,@rtorrentLiteral,rtorrentIdentifier,rtorrentStringCommand,rtorrentPD,rtorrentP,rtorrentB

" Commands                                                               "{{{1

" Cmd list "{ ... }"
call s:mkNestedParens('rtorrentB',  'rtorrentBC', 'start=+{+ skip=+{.\{-}}+ end=+}+', '@rtorrentRhsTop,rtorrentPD', 2)
call s:mkNestedParens('rtorrentSB', 'rtorrentBC', 'start=+{+ skip=+{.\{-}}+ end=+}+', '@rtorrentSRhsTop,rtorrentSPD', 2)

" Cmd parens "( <cmd>[, <arg>...] )"
call s:mkNestedParens('rtorrentP',  'rtorrentPC', 'start=+(+ skip=+(.\{-})+ end=+)+', '@rtorrentRhsTop,rtorrentPD', 2)
call s:mkNestedParens('rtorrentSP', 'rtorrentPC', 'start=+(+ skip=+(.\{-})+ end=+)+', '@rtorrentSRhsTop,rtorrentSPD', 2)

" Cmd parens 2 "(( <command>[, <args>...] ))"
call s:mkNestedParens('rtorrentPD',  'rtorrentPDC', 'start=+((+ skip=+((.\{-}))+ end=+))+', '@rtorrentRhsTop', 4)
call s:mkNestedParens('rtorrentSPD', 'rtorrentPDC', 'start=+((+ skip=+((.\{-}))+ end=+))+', '@rtorrentSRhsTop', 4)

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
hi          rtorrentBC1              ctermfg=135
hi          rtorrentBC2              ctermfg=133
" Parentheses: single
hi          rtorrentPC1              ctermfg=105
hi          rtorrentPC2              ctermfg=103
" Parentheses: dual (4 levels)
hi          rtorrentPDC1             ctermfg=160
hi          rtorrentPDC2             ctermfg=167
hi          rtorrentPDC3             ctermfg=165
hi          rtorrentPDC4             ctermfg=162
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
"hi def link rtorrentIdentifier       Identifier
hi def link rtorrentIdentifierPrefix Type
hi def link rtorrentMethodName       Keyword
hi def link rtorrentMethodNameEnd    Keyword
hi def link rtorrentKnownCmd         Keyword
hi def link rtorrentArgArgument      PreProc

" Define current syntax                                                   {{{1
let b:current_syntax = 'rtorrent'

let &cpo = s:cpo_save
unlet s:cpo_save
