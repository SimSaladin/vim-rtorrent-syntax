" vint: -ProhibitAutocmdWithNoGroup
" ==============================================================================
" Vim ftdetect file
" Language: rTorrent configuration language ('rtorrent')
" Original Author: Samuli Thomasson <https://github.com/SimSaladin>
" ==============================================================================

au BufRead,BufNewFile {[Rr][Tt]orrent,_rtlocal}.[Rr][Cc] setfiletype rtorrent
au BufRead,BufNewFile *rtorrent.rc* setfiletype rtorrent
au BufRead,BufNewFile */{[Rr]torrent.[dD],.rtorrent}/*.[Rr][Cc]{,.include} setlocal filetype=rtorrent

