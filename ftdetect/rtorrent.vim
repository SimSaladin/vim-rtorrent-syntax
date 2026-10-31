" Vim ftdetect for filetype: rtorrent

au BufRead,BufNewFile {rtorrent,_rtlocal}.rc        setfiletype rtorrent
au BufRead,BufNewFile */{rtorrent.d,.rtorrent}/*.rc setfiletype rtorrent
