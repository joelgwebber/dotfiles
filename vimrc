syntax enable
set ts=2
set sw=2
set ai
set et
set nowrap
set ruler
set switchbuf=useopen

" Kind of gross, but no other good way exists to clear a terminal's scrollback.
nmap <c-w><c-l> :set scrollback=1 \| sleep 100m \| set scrollback=10000<cr>
tmap <c-w><c-l> <c-\><c-n><c-w><c-l>i<c-s-l>

" execute pathogen#infect()
" set linebreak
" noremap <silent> k gk
" noremap <silent> j gj
" noremap <silent> 0 g0
" noremap <silent> $ g$

