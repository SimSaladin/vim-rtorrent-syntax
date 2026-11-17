" ==============================================================================
" Vim syntax file
" Language: rTorrent configuration language ('rtorrent')
" Original Author: Samuli Thomasson <https://github.com/SimSaladin>
" ==============================================================================
" Notes:                                                                  {{{1
" A "(...)" instantiates an internal "torrent" with a function flag for
" runtime evaluation and command execution. Aka function evaluation.
"
" A "((...))" escapes the function object when pasing it directly as an
" argument to commands like "method.set_key", "schedule", event triggers.
"
" A "{...}" make a list object.
"
" A "{(...)}" wraps and escapes embedded function objects so you don't need to
" individually double quote or double-parenthesize each nested function block. 
"
" # Passes the block as a list-wrapped function, preventing argument parsing issues inside the shell command
" method.set_key = event.download.erased, rm_files, {(branch, ((d.custom, incomplete)), ((execute, rm, -rf, --, (d.base_path) )) )}


" Quit if syntax already loaded                                           {{{1
if exists('b:current_syntax')
  finish
endif

scriptencoding utf-8

let s:cpo_save = &cpo
set cpo&vim
"}}}1
                                                                         "{{{
function! s:SynNext(k, x, prefix = 'Stmt')                               "{{{
  return 'rtorrent' .. a:prefix .. a:k .. (a:x > 0 ? a:x : '')
endfunction"}}}
function! s:SynMatch(k, i, pat, contains, nextgroup)                     "{{{
  execute 'syn match ' .. s:SynNext(a:k, a:i) .. a:pat ..
        \ ' contains=' .. a:contains ..
        \ ' nextgroup=' .. (empty(a:nextgroup) ? s:SynNext(a:k, a:i + 1) : a:nextgroup) ..
        \ ' contained transparent skipwhite'
endfunction"}}}
function! s:SynRegion(k, i, contains, nextgroup)                         "{{{
    execute 'syn region ' .. s:SynNext(a:key, a:i) ..
          \ ' start=/\S/' ..
          \ ' matchgroup=rtorrentDelimiter end=/,\s*\%(\\\n\s*\)\?/' ..
          \ ' contains=' .. a:contains ..
          \ ' nextgroup=' .. a:nextgroup ..
          \ ' contained transparent skipwhite'
endfunction"}}}
function! s:DefStatement(key, pat, args) abort                           "{{{
  call s:SynMatch(a:key       , 0, '/\%(' .. a:pat .. '\)\s*=/', 'rtorrentMethodName,rtorrentEq',        s:SynNext(a:key, 1))
  call s:SynMatch(a:key .. 'I', 0, '/\%(' .. a:pat .. '\)\s*,/', 'rtorrentMethodName,rtorrentDelimiter', s:SynNext(a:key, 1))
  let i = 1
  for x in a:args
    let nextgroup = (i + 1 >= len(a:args)) ? a:args[-1] : s:SynNext(a:key, i + 1)
    call s:SymRegion(a:key, i, x, nextgroup)
    let i = i + 1
  endfor
  execute 'syn cluster ntorrentMethodStatement add=' . s:SynNext(a:key, 0)
  execute 'syn cluster rtorrentMethodCall      add=' . s:SynNext(a:key . 'I', 0)
endfunction"}}}
function! s:mkNestedParens(name, matchgroup, match, contains, limit)     "{{{
  let depth = 1
  while depth <= a:limit
    execute 'syn region ' .. a:name .. (depth == 1 ? '' : depth) ..
          \ ' contained matchgroup=' .. a:matchgroup . depth .. ' ' .. a:match ..
          \ ' contains=' .. a:contains .. ',' .. a:name .. (depth + 1 > a:limit ? '' : depth + 1) ..
          \ ' skipwhite fold'
    let depth += 1
  endwhile
endfunction"}}}
"}}}
" Comments and TODOs etc.                                                 {{{1

" Include "." in keywords
syn iskeyword @,48-57,_,.,192-255

syn keyword rtorrentTodo contained FIXME NOTE TODO XXX

syn region rtorrentComment start=+^\s*#+me=s skip=+\n\s*#+ end=+$+ contains=@Spell,rtorrentTodo keepend fold

" Base defaults                                                           {{{1
"
" Stuff on RHS that is NOT inside quotes:
"
" - rtorrentEq TODO
" - rtorrentDelimiter TODO
" - @rtorrentLiteral TODO
" - rtorrentType TODO
" - rtorrentIdentifier TODO
" - rtorrentStringCommand TODO
"
" Contained Statement RHS: Accurate hilighting here depends on which command is on the LHS.
syn match   rtorrentRhs           contained +\_.*+ contains=@rtorrentRhsTop  skipwhite transparent keepend

syn cluster rtorrentRhsTop contains=rtorrentComment
syn cluster rtorrentRhsTop add=rtorrentFP,rtorrentPD,rtorrentB,rtorrentP
syn cluster rtorrentRhsTop add=rtorrentDelimiter,rtorrentType

"syn cluster rtorrentRhsTop  add=rtorrentIdentifier
"syn cluster rtorrentRhsTop  add=@rtorrentString1L
"syn cluster rtorrentTOP add=rtorrentEq,rtorrentPD,rtorrentP,rtorrentB
"syn cluster rtorrentTOP add=rtorrentDelimiter,rtorrentType
"syn cluster rtorrentTOP add=rtorrentIdentifier
"syn cluster rtorrentTOP add=rtorrentStringCommand

"syn cluster rtorrentSRhsTop add=rtorrentSB,rtorrentSP,rtorrentDelimiter,rtorrentIdentifier,@rtorrentSLiteral


" 2. Parentheses etc.                                                     {{{1

" Braces: 2 levels
" Cmd list "{ ... }"
call s:mkNestedParens('rtorrentB',  'rtorrentBC', 'start=+{+ skip=+{\_.\{-}}+ end=+}+', '@rtorrentRhsTop,rtorrentPD', 2)
call s:mkNestedParens('rtorrentSB', 'rtorrentBC', 'start=+{+ skip=+{\_.\{-}}+ end=+}+', '@rtorrentSRhsTop,rtorrentSPD', 2)

" Parentheses: 2 levels
" Cmd parens "( <cmd>[, <arg>...] )"
call s:mkNestedParens('rtorrentP',  'rtorrentPC', 'start=+(+ skip=+(\_.\{-})+ end=+)+', '@rtorrentRhsTop,rtorrentPD', 5)
call s:mkNestedParens('rtorrentSP', 'rtorrentPC', 'start=+(+ skip=+(\_.\{-})+ end=+)+', '@rtorrentSRhsTop,rtorrentSPD', 5)

" Wrapped FunctionList: multi-layered "{( ... )}"
call s:mkNestedParens('rtorrentFP',  'rtorrentFC', 'start=+{(+  skip=+{(\_.\{-})}+ end=+)}+', '@rtorrentRhsTop', 5)
call s:mkNestedParens('rtorrentFPS', 'rtorrentFC', 'start=+{(+  skip=+{(\_.\{-})}+ end=+)}+', '@rtorrentSRhsTop', 5)

" Double Parentheses: 4 levels
" Cmd parens 2 "(( <command>[, <args>...] ))"
call s:mkNestedParens('rtorrentPD',  'rtorrentPDC', 'start=+((+ skip=+((\_.\{-}))+ end=+))+', '@rtorrentRhsTop', 4)
call s:mkNestedParens('rtorrentSPD', 'rtorrentPDC', 'start=+((+ skip=+((\_.\{-}))+ end=+))+', '@rtorrentSRhsTop', 4)

" 1. Atomic items (uniform hilight)                                       {{{1

" Recognized keywords are to be hilighted.
syn keyword rtorrentBool  true yes no off on disable enable contained skipwhite

" Recognized keywords for types  identifiers.   "simple", "string", "static", "etc."
syn keyword rtorrentType simple string const private value multi rlookup static contained nextgroup=rtorrentTypeDelim skipwhite

" Scalar values denoting size or rate. "120mB", "12534M"
syn match   rtorrentSizeLit "\<\d\+[KMG]\?\>" contained skipwhite

" Number literals without unit: "123", "-300", "1.2346"
syn match   rtorrentNumber "-\?\<\d\+\%([.]\d\+\)\?\>" nextgroup=rtorrentTypeDelim contained skipwhite

" Notation for key combinations: "^Q", "^A"
syn match   rtorrentCtrlChar "\^[a-zA-Z0-9]\>" contained skipwhite

" String literals & escaping (first 2 levels)                             {{{1

syn match   rtorrentStringEscape2 '\\\\\\.' contained
syn match   rtorrentStringEscape  '\\\_.' contained

function! s:mkStringMatch(level, name, contains)                         "{{{
  let escs = '"'
  let i = a:level
  while i > 0
    let escs = escape(escs, '"\')
    let i -= 1
  endwhile
  execute 'syn match ' .. a:name .. ' +\%(\\\)\@<!' .. escs .. '\%(\_.\{-}\)\%(\\\)\@<!' .. escs .. '+'
        \ ' contains=' .. a:contains
        \ ' contained keepend excludenl'
endfunction"}}}
function! s:mkNestedStrings(base, level, contains)                       "{{{
  let l = 0
  while l <= a:level
    call s:mkStringMatch(l, a:base .. l, a:base .. (l + 1) .. ',' .. a:contains)
    let l += 1
  endwhile
endfunction"}}}

call s:mkNestedStrings('rtorrentStringL', 3, '@torrentRhsTop,rtorrentEscape')

" TOP:
syn cluster rtorrentRhsTop  add=rtorrentString1L,rtorrentStringL1
syn cluster rtorrentRhsTop  add=@rtorrentSimpleLiteral

" For string-serialized commands...
syn region  rtorrentStringCommand matchgroup=String start=+"+   skip=+\\\\\|\\"+ end=+"+   contained contains=@rtorrentRhsTop,rtorrentString2L,rtorrentSPD,rtorrentEq
syn match   rtorrentStringy       "\S.\{-}" contained
syn region  rtorrentStringy       start=+"+   skip=+\\"+       end=+"+   contained contains=rtorrentStringEscape,@Spell

" Strings and characters                                                 "{{{1

" String1L:      String literal ("literal")
" String2L:      String within string "...\"inner string\""
" StringCommand: String literal is a command
" Literal:       Some literal value (top-level)
" SLiteral:      Some literal value (inside command string)
" Stringy:       Implicit string argument

syn cluster rtorrentSimpleLiteral contains=rtorrentBool,rtorrentNumber,rtorrentSizeLit,rtorrentTimeInterval,rtorrentCtrlChar

" Intervals as recognized by some rTorrent commands:  "[dd:]hh:mm:ss"
syn match   rtorrentTimeInterval  "\<\%(\d\d:\)\?\d\d:\d\d:\d\d" contains=rtorrentTypeDelim,rtorrentIntervalSecs contained skipwhite keepend

syn match  rtorrentIntervalSecs +:\d\d+ contained skipwhite

" Not Contained TOP:
"syn cluster rtorrentSLiteral      contains=rtorrentType,rtorrentString2L

" Statements & methods: the TOP LEVEL                                     {{{1

" Statement TOP: transparent syntax item for one top-level statement. E.g.  "foo = bar\..."
syn match   rtorrentStatement "^\s*[a-zA-Z]\k*\(\\\\\|\\\n\|.\)*\_$" contains=rtorrentLhs,@NoSpell keepend transparent fold

" Contained Statement LHS: e.g. method identifier and the "=" -singn.  "foobar ="
syn match rtorrentLhs           contained +^\k\+\>\s*=+  contains=rtorrentMethodName,rtorrentEq nextgroup=rtorrentRhs skipwhite transparent
syn match rtorrentMethodName    contained +\k\++         contains=rtorrentDot,rtorrentMethodNameEnd
syn match rtorrentMethodNameEnd contained +\.\%(set_key\|set\|bind_key\)\>+ms=s+1,lc=1

"
" - rtorrentIdentifier TODO
" - rtorrentStringCommand TODO
" - rtorrentStringy TODO

"syn match rtorrentIdentifier       "\c\%(\k\|[=.-]\)\+\>" contained contains=rtorrentArgArgument,rtorrentDot,rtorrentKnownCmd,rtorrentIdentifierPrefix
"syn match rtorrentIdentifierPrefix /\k\+\./me=e-1         contained nextgroup=rtorrentObjectMethod
"syn match rtorrentObjectMethod     "\c\%(\k\|[=.-]\)\+\>" contained contains=rtorrentDot
" Stuff that IS inside (level 1) quotes:
"syn cluster rtorrentCommandArgumentStr add=rtorrentIdentifier,rtorrentStringCommand,rtorrentStringy
"syn cluster rtorrentCommandArgumentStr add=rtorrentPD,rtorrentP,rtorrentB
"syn cluster rtorrentMethodStatement contains=rtorrentLhs
"syn cluster rtorrentMethodStatement add=rtorrentStmtViewFilterOn
"syn cluster rtorrentMethodCall      add=rtorrentStmtViewFilterOnI

" Misc                                                                    {{{1

syn match   rtorrentTypeDelim    contained '[-|:]'      skipwhite skipnl
syn match   rtorrentDelimiter    contained '[,;]\|\\\n' skipwhite skipnl
syn match   rtorrentDot          contained '\.'
syn match   rtorrentEq           contained '=' skipwhite skipnl nextgroup=@rtorrentSimpleLiteral

" Placeholders, (argument.0) etc. "\<argument\.[0-3]\>"
" Command specific overrides                                             "{{{1

" "schedule = <name>, <time>, <time>, <command>"
" "method.(insert|set_key|insert.*) = ..."
" "if = <cond>, <then>, <elif_else>"
" "branch = <cond>, <then>, <elif_else>"


"call s:DefStatement('Schedule',           'schedule',              ['rtorrentStringy', '@rtorrentRhsTop', '@rtorrentRhsTop', '@rtorrentCommandArgumentTOP'])
"call s:DefStatement('MethodInsert',       'method\.insert',        ['rtorrentStringy', 'rtorrentType', '@rtorrentCommandArgumentTOP'])
"call s:DefStatement('MethodSet',          'method\.set',           ['rtorrentStringy', '@rtorrentCommandArgumentTOP'])
"call s:DefStatement('MethodSetKey',       'method\.set_key',       ['rtorrentStringy', 'rtorrentStringy', '@rtorrentCommandArgumentTOP'])
"call s:DefStatement('MethodInsertValue',  'method\.insert\.value', ['rtorrentStringy','@rtorrentRhsTop'])
"call s:DefStatement('MethodInsertSimple', 'method\.insert\.\%(simple\|c_simple\|s_c_simple\)', ['rtorrentStringy','@rtorrentCommandArgumentTOP'])
"call s:DefStatement('Keyword1',           'catch\|try\|print\|not', ['@rtorrentCommandArgumentTOP'])
"call s:DefStatement('Keyword2',           'if\|branch',             ['@rtorrentCommandArgumentTOP', '@rtorrentCommandArgumentTOP', '@rtorrentCommandArgumentTOP'])
"call s:DefStatement('View',               'view\.\%(filter\|sort\.current\|sort\.new\)', ['rtorrentStringy', '@rtorrentCommandArgumentTOP'])
" view.filter_on = STRING[, STRING[, ...]
"syn match   rtorrentStmtViewFilterOn  /\%(view\.\%(filter_on\)\)\s*=/  contained transparent contains=rtorrentMethodName,rtorrentEq        nextgroup=rtorrentStmtViewFilterOn1 skipwhite
"syn match   rtorrentStmtViewFilterOnI /\%(view\.\%(filter_on\)\)\s*,/  contained transparent contains=rtorrentMethodName,rtorrentDelimiter nextgroup=rtorrentStmtViewFilterOn1 skipwhite
"syn region  rtorrentStmtViewFilterOn1 start=/\S/ matchgroup=rtorrentDelimiter end=/,\s*\%(\\\n\s*\)\?/  contained transparent contains=@rtorrentCommandArgumentStr nextgroup=rtorrentStmtViewFilterOn1 skipwhite

syn match rtorrentCommandExecute /\%(\%(\_^\|(\)\s*\)\@<=\k\+\ze\s*\%(\_$\|,\|)\)/ contained
      \ containedin=rtorrentP,rtorrentP2,rtorrentPD,rtorrentPD2,rtorrentPD3,rtorrentPD4,rtorrentPD5,rtorrentFP,rtorrentFP2,rtorrentFP3,rtorrentFP4,rtorrentFP5

syn keyword rtorrentArgArgument
      \ argument.0 argument.1 argument.2 argument.3
      \ contained containedin=rtorrentCommandExecute

" Well-known identifiers
syn keyword rtorrentCommandBuiltin
      \ and or if import branch try_import import.return
      \ if branch try_import cat print do try catch not false and or
      \ execute.nothrow execute.capture_system
      \ execute.system execute.system.nothrow execute.system.capture execute.system.capture_nothrow
      \ system.has log.execute system.env.default  system.env system.pid system.hostname
      \ method.insert schedule
      \ contained containedin=rtorrentCommandExecute

" Sync:                                                                   {{{1

syn sync minlines=50

" Hilighting:                                                             {{{1

" Literals and Constants
hi def link rtorrentBool             Boolean
hi def link rtorrentNumber           Number
hi def link rtorrentSizeLit          Constant
hi def link rtorrentTimeInterval     Constant
hi def link rtorrentCtrlChar         SpecialChar
hi def link rtorrentType             Type

" Nested sttring literals
hi def link rtorrentStringL1         String
hi def link rtorrentStringL2         Underlined
hi def      rtorrentStringL3         cterm=underline ctermfg=5 gui=underline guifg=#d33682

" Strings and string-like
hi def link rtorrentStringy          String
hi def link rtorrentStringEscape     SpecialChar
hi def link rtorrentStringEscape2    SpecialChar

" Inside string literals TODO
hi def link rtorrentString2L         Underlined
hi def link rtorrentSStringDelim     Underlined

" Delimiters & operators
hi def link rtorrentDelimiter        Delimiter
hi def link rtorrentTypeDelim        Operator
"hi def link rtorrentEq               Operator
hi def link rtorrentDot              Operator

" Method Names:
hi          rtorrentMethodName       ctermfg=3 guifg=#b58900
hi def link rtorrentMethodNameEnd    PreProc
hi def link rtorrentKnownCmd         Keyword
hi def link rtorrentArgArgument      PreProc
hi def link rtorrentObjectMethod     Identifier
"hi def link rtorrentCommandExecute   Identifier
hi def link rtorrentCommandBuiltin   Keyword
hi def link rtorrentIdentifierPrefix Type
"hi def link rtorrentIdentifier       Identifier


" Function List: single 5
hi rtorrentFC1   ctermfg=5   guifg=#B87E00 gui=bold cterm=bold
hi rtorrentFC2   ctermfg=4   guifg=#B86B00 gui=bold cterm=bold
hi rtorrentFC3   ctermfg=6   guifg=#B85700 gui=bold cterm=bold
hi rtorrentFC4   ctermfg=5   guifg=#B84200 gui=bold cterm=bold
hi rtorrentFC5   ctermfg=4   guifg=#B82C00 gui=bold cterm=bold

" Parentheses: custom colors for 5 levels
hi rtorrentPC1   ctermfg=105 guifg=#0095CA gui=bold cterm=bold
hi rtorrentPC2   ctermfg=103 guifg=#2aa198 gui=bold cterm=bold
hi rtorrentPC3   ctermfg=167 guifg=#9600D6 gui=bold cterm=bold
hi rtorrentPC4   ctermfg=165 guifg=#4544C9 gui=bold cterm=bold
hi rtorrentPC5   ctermfg=165 guifg=#0800D6 gui=bold cterm=bold

" Double Parentheses: custom colors, 4 levels
hi rtorrentPDC1  ctermfg=167 guifg=#E61052
hi rtorrentPDC2  ctermfg=165 guifg=#C82410 gui=bold cterm=bold
hi rtorrentPDC3  ctermfg=160 guifg=#C21039
hi rtorrentPDC4  ctermfg=162 guifg=#82357E gui=bold cterm=bold

" Braces: custom  colors for 2 levels
hi rtorrentBC1   ctermfg=135 guifg=#71A100 gui=bold cterm=bold
hi rtorrentBC2   ctermfg=133 guifg=#437E00 gui=bold cterm=bold

" Comments etc.
hi def link rtorrentTodo             Todo
hi def link rtorrentComment          Comment
hi def link rtorrentLineComment      Comment

" OUTRO: Define current syntax                                            {{{1
let b:current_syntax = 'rtorrent'

let &cpo = s:cpo_save
unlet s:cpo_save
