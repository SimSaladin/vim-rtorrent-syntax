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

let s:cpo_save = &cpoptions
set cpoptions&vim
"}}}1

function! s:mkNestedParens(name, matchgroup, match, contains, limit)     "{{{
  for depth in range(1, a:limit)
    let name = a:name .. (depth == 1 ? '' : depth)
    let inner = a:name .. (depth + 1 > a:limit ? '' : depth + 1)
    execute 'syn region ' .. name ..
          \ ' matchgroup=' .. a:matchgroup .. depth .. ' ' .. a:match ..
          \ ' contains=' .. a:contains .. ',' .. inner ..
          \ ' contained skipwhite fold keepend extend'
  endfor
endfunction"}}}
function! s:quoteNested(level)
  let delim = '"'
  let pre = '\\'
  for i in range(1, a:level)
    let delim = escape(delim, '"\')
    let pre = escape(pre, '\')
  endfor
  return '\%([^\\]\%(' .. pre .. '\)*\)\@<=' .. delim
endfunction
function! s:mkStringMatch(level, name, contains, matchgroup)                         "{{{
  let delim = '"'
  let pre = '\'
  for i in range(1, a:level)
    let delim = escape(delim, '"\')
    "if i > 1
    let pre = escape(pre, '\')
    "endif
  endfor
  if a:level > 1
    let start = '\%(\_^\|[^\\]\%(' .. pre .. '\)*\)\@<='
    let end = '\%(\_^\|[^\\]\%(' .. pre .. pre .. '\)*\)\@<='
  else
    let start = '\%(\_^\|[^\\]\%(\\\\\)*\)\@<='
    let end = '\%(\_^\|[^\\]\%(\\\\\)*\)\@<='
  endif
  execute 'syn region ' .. a:name ..
        \ ' matchgroup=' .. a:matchgroup ..
        \ ' start=+' .. start .. delim .. '+' ..
        \ ' end=+' .. end .. delim .. '+' ..
        \ (a:level > 1 ? (' end=+' .. s:quoteNested(a:level - 1) .. '+me=s-1') : '') ..
        \ ' contains=' .. a:contains ..
        \ ' contained keepend excludenl extend'
endfunction"}}}
function! s:mkNestedStrings(base, limit, contains)                       "{{{
  for l in range(1, a:limit)
    call s:mkStringMatch(l, a:base .. l, a:base .. (l + 1) .. ',' .. a:contains, l == 1 ? 'String' : (a:base .. l))
  endfor
endfunction"}}}

" Comments and TODOs etc.                                                 {{{1

" Include "." in keywords
syn iskeyword @,48-57,_,.,192-255

syn keyword rtorrentTodo contained FIXME NOTE TODO XXX

syn region rtorrentComment start=+^\s*#+me=s skip=+\n\s*#+ end=+$+ contains=@Spell,rtorrentTodo keepend fold

" Literal values                                                          {{{1

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

call s:mkNestedStrings('rtorrentStringL', 3, '@Spell')
call s:mkNestedStrings('rtorrentStringEval', 3, '@rtorrentParensS1,rtorrentCommand')

syn cluster rtorrentSimpleLiteral contains=rtorrentBool,rtorrentNumber,rtorrentSizeLit,rtorrentTime,rtorrentCtrlChar

" Time/interval as recognized by some rTorrent commands: "[dd:]hh:mm[:ss]"
syn match   rtorrentTime  "\<\d\d:\d\d\>"           contains=rtorrentTimeHours contained skipwhite keepend
syn match   rtorrentTime  "\<\d\d:\d\d:\d\d\>"      contains=rtorrentTimeHours contained skipwhite keepend
syn match   rtorrentTime  "\<\d\d:\d\d:\d\d:\d\d\>" contains=rtorrentTimeDays  contained skipwhite keepend
syn match   rtorrentTimeDays +\d\d+     contained nextgroup=rtorrentTimeHours
syn match   rtorrentTimeHours +:\?\d\d+ contained contains=rtorrentTypeDelim nextgroup=rtorrentTimeMins
syn match   rtorrentTimeMins +:\d\d+    contained contains=rtorrentTypeDelim nextgroup=rtorrentTimeSecs
syn match   rtorrentTimeSecs +:\d\d+    contained contains=rtorrentTypeDelim

" Statement: TOP LEVEL                                                   {{{1

" Transparent syntax item for one top-level statement. E.g.  "foo = bar\..."
syn region rtorrentStatement start=+^\zs[a-zA-Z]+ skip=+\\\n+ end=+\_$+ contains=rtorrentLhs,@NoSpell keepend transparent fold

" Contained Statement LHS: e.g. method identifier and the "=" -singn.  "foobar ="
syn match rtorrentLhs contained +^\k\+\>\s*=+  contains=rtorrentCommand nextgroup=rtorrentRhs skipwhite transparent

" Contained Statement RHS: Accurate hilighting here depends on which command is on the LHS.
"syn match   rtorrentRhs contained +\%(.*\\\n\)*.*\_$+ contains=@rtorrentRhsTop  transparent keepend
syn region rtorrentRhs start=+\zs.+ skip=+\\\n+ end=+\_$+ contained contains=@rtorrentRhsTop  transparent keepend

syn cluster rtorrentParens contains=rtorrentFP,rtorrentPD,rtorrentB,rtorrentP
syn cluster rtorrentParensS1 contains=rtorrentFPS,rtorrentSPD,rtorrentSB,rtorrentSP

syn cluster rtorrentRhsTop contains=@rtorrentParens,@rtorrentSimpleLiteral,rtorrentStringL1,rtorrentDelimiter,rtorrentType
syn cluster rtorrentRhsTopS1 contains=@rtorrentParensS2,@rtorrentSimpleLiteral,rtorrentStringL2,rtorrentDelimiter,rtorrentType

" Parens, braces                                                          {{{1

" Braces:
" Cmd list "{ ... }"
call s:mkNestedParens('rtorrentB',  'rtorrentBC', 'start=+{+ skip=+{\_.\{-}}+ end=+}+', '@rtorrentRhsTop', 2)
call s:mkNestedParens('rtorrentSB', 'rtorrentBC', 'start=+{+ skip=+{\_.\{-}}+ end=+}+', '@rtorrentRhsTopS1', 2)

" Parens:
" Cmd parens "( <cmd>[, <arg>...] )"
call s:mkNestedParens('rtorrentP',  'rtorrentPC', 'start=+(+ skip=+(\_.\{-})+ end=+)+', '@rtorrentRhsTop', 5)
call s:mkNestedParens('rtorrentSP', 'rtorrentPC', 'start=+(+ skip=+(\_.\{-})+ end=+)+', '@rtorrentRhsTopS1', 5)

" Wrapped FunctionList: multi-layered "{( ... )}"
call s:mkNestedParens('rtorrentFP',  'rtorrentFC', 'start=+{(+  skip=+{(\_.\{-})}+ end=+)}+', '@rtorrentRhsTop', 5)
call s:mkNestedParens('rtorrentFPS', 'rtorrentFC', 'start=+{(+  skip=+{(\_.\{-})}+ end=+)}+', '@rtorrentRhsTopS1', 5)

" Double Parens:
" Cmd parens 2 "(( <command>[, <args>...] ))"
call s:mkNestedParens('rtorrentPD',  'rtorrentPDC', 'start=+((+ skip=+((\_.\{-}))+ end=+))+', '@rtorrentRhsTop', 4)
call s:mkNestedParens('rtorrentSPD', 'rtorrentPDC', 'start=+((+ skip=+((\_.\{-}))+ end=+))+', '@rtorrentRhsTopS1', 4)

" Misc                                                                    {{{1

syn match   rtorrentTypeDelim    contained '[-|:]'      skipwhite skipnl
syn match   rtorrentDelimiter    contained '[,;]\|\\\n' skipwhite skipnl
syn match   rtorrentEq           contained '=' skipwhite skipnl

" Commands                                                               "{{{1

" "schedule = <name>, <time>, <time>, <command>"
" "method.(insert|set_key|insert.*) = ..."
" "if = <cond>, <then>, <elif_else>"
" "branch = <cond>, <then>, <elif_else>"
" view.filter_on = STRING[, STRING[, ...]

syn match rtorrentCommand /\%(\%(\_^\|(\)\s*\)\@<=\k\+\s*\%(\_$\|,\|\ze)\)/ contained skipwhite
      \ contains=rtorrentDelimiter
      \ containedin=rtorrentP[2-9]\?,rtorrentPD[2-9]\?,rtorrentFP[2-9]\?
syn match rtorrentCommand /\%(\_^\|"\s*\)\zs\k\+\ze\s*=/ contained
syn match rtorrentCommandName /\k\+/ contained containedin=rtorrentCommand
syn match rtorrentCommandName /"\k\+"/ contained containedin=rtorrentCommand

" Placeholders, (argument.0) etc. "\<argument\.[0-3]\>"
syn keyword rtorrentArgumentPlaceholder
      \ argument.0 argument.1 argument.2 argument.3
      \ contained containedin=rtorrentCommand

" builtin commands get different highlight
syn keyword rtorrentCommandBuiltin
      \ print cat value try catch if branch not false and or do
      \ less greater equal compare match
      \ import try_import import.return
      \ lua.execute lua.execute.str
      \ execute.nothrow execute.capture_system
      \ execute.system execute.system.nothrow execute.system.capture execute.system.capture_nothrow
      \ system.has system.env.default system.env system.pid system.hostname
      \ method.insert method.insert.value method.insert.bool method.insert.simple method.insert.list
      \ method.erase method.redirect method.get method.set
      \ method.has_key method.set_key method.list_keys
      \ schedule
      \ log.execute
      \ view.filter view.filter_on
      \ view.sort
      \ contained containedin=rtorrentCommandName

function! s:mkCommandArgs(cmd)
  let rhsName = 'rtorrent_' .. substitute(a:cmd, '[^A-Za-z0-9]\+', '_', 'g')
  execute 'syn match rtorrentLhs /' .. a:cmd .. '\s*=/' ..
        \ ' nextgroup=' .. rhsName ..
        \ ' contained skipwhite' ..
        \ ' contains=rtorrentEq,rtorrentCommandName' ..
        \ ' containedin=rtorrentStatement'
  execute 'syn match rtorrentCommand /' .. a:cmd .. '\s*,/' ..
        \ ' nextgroup=' .. rhsName ..
        \ ' contained skipwhite' ..
        \ ' contains=rtorrentDelimiter,rtorrentCommandName' ..
        \ ' containedin=rtorrentP[2-9]\?,rtorrentPD[2-9]\?,rtorrentFP[2-9]\?'
endfunction
function! s:mkArg(cmd, pos, contains, next = '')
  let name = 'rtorrent_' .. substitute(a:cmd, '[^A-Za-z0-9]\+', '_', 'g') .. (a:pos > 1 ? '_' .. a:pos : '')
  let next = a:next ==# '' ? ('rtorrent_' .. substitute(a:cmd, '[^A-Za-z0-9]\+', '_', 'g') .. '_' .. (a:pos + 1)) : a:next
  execute 'syn region ' .. name .. ' start=/\zs\S/ matchgroup=rtorrentDelimiter end=/,\s*\%(\\\n\)\?/ contained skipwhite keepend' ..
        \ ' contains=' .. a:contains .. ',@rtorrentParens' ..
        \ ' nextgroup=' .. next
endfunction

call s:mkCommandArgs('method.insert')
call s:mkArg('method.insert', 1, 'rtorrentCommandName,rtorrentStringL1')
call s:mkArg('method.insert', 2, 'rtorrentType,rtorrentTypeDelim', '@rtorrentParens,rtorrentStringEval1')

" Sync:                                                                   {{{1

syn sync minlines=50

" Hilighting:                                                             {{{1

" Methods:
hi def link rtorrentCommandName         Identifier
hi def link rtorrentArgumentPlaceholder PreProc
hi def link rtorrentCommandBuiltin      Keyword
"hi          rtorrentMethodName       ctermfg=3 guifg=#b58900

" String literals
hi def link rtorrentStringL1         String
hi def link rtorrentStringL2         Underlined
hi def      rtorrentStringL3         cterm=underline ctermfg=5 gui=underline guifg=#d33682
hi def link rtorrentStringEval1      rtorrentStringL1
hi def link rtorrentStringEval2      rtorrentStringL2
hi def link rtorrentStringEval3      rtorrentStringL3

" Function List: single 5
hi def rtorrentFC1   ctermfg=5   guifg=#B87E00 gui=bold cterm=bold
hi def rtorrentFC2   ctermfg=4   guifg=#B86B00 gui=bold cterm=bold
hi def rtorrentFC3   ctermfg=6   guifg=#B85700 gui=bold cterm=bold
hi def rtorrentFC4   ctermfg=5   guifg=#B84200 gui=bold cterm=bold
hi def rtorrentFC5   ctermfg=4   guifg=#B82C00 gui=bold cterm=bold

" Parentheses: custom colors for 5 levels
hi def rtorrentPC1   ctermfg=105 guifg=#0095CA gui=bold cterm=bold
hi def rtorrentPC2   ctermfg=103 guifg=#2aa198 gui=bold cterm=bold
hi def rtorrentPC3   ctermfg=167 guifg=#9600D6 gui=bold cterm=bold
hi def rtorrentPC4   ctermfg=165 guifg=#4544C9 gui=bold cterm=bold
hi def rtorrentPC5   ctermfg=165 guifg=#0800D6 gui=bold cterm=bold

" Double Parentheses: custom colors, 4 levels
hi def rtorrentPDC1  ctermfg=167 guifg=#E61052
hi def rtorrentPDC2  ctermfg=165 guifg=#C82410 gui=bold cterm=bold
hi def rtorrentPDC3  ctermfg=160 guifg=#C21039
hi def rtorrentPDC4  ctermfg=162 guifg=#82357E gui=bold cterm=bold

" Braces: custom  colors for 2 levels
hi def rtorrentBC1   ctermfg=135 guifg=#71A100 gui=bold cterm=bold
hi def rtorrentBC2   ctermfg=133 guifg=#437E00 gui=bold cterm=bold

" Delimiters
hi def link rtorrentDelimiter        Delimiter
hi def link rtorrentTypeDelim        Operator
"hi def link rtorrentEq               Operator

" Literals and Constants
hi def link rtorrentBool             Boolean
hi def link rtorrentNumber           Number
hi def link rtorrentSizeLit          Constant
hi def link rtorrentCtrlChar         SpecialChar
hi def link rtorrentType             Type
hi def link rtorrentTimeDays         Type
hi def link rtorrentTimeHours        PreProc
hi def link rtorrentTimeMins         Number
hi def link rtorrentTimeSecs         Number

" Comments etc.
hi def link rtorrentTodo             Todo
hi def link rtorrentComment          Comment
hi def link rtorrentLineComment      Comment

" OUTRO: Define current syntax                                            {{{1
let b:current_syntax = 'rtorrent'

let &cpoptions = s:cpo_save
unlet s:cpo_save
