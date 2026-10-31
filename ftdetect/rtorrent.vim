" vint: -ProhibitAutocmdWithNoGroup

" rtorrent
au BufRead,BufNewFile {[Rr][Tt]orrent,_rtlocal}.[Rr][Cc]        setfiletype rtorrent
au BufRead,BufNewFile *rtorrent.rc*                             setfiletype rtorrent
au BufRead,BufNewFile */{[Rr]torrent.[dD],.rtorrent}/*.[Rr][Cc]{,.include} setfiletype rtorrent
