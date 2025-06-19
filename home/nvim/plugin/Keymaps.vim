" free movement
nnoremap j gj
nnoremap k gk

" start a newline
nnoremap <A-o> o<Esc>
nnoremap <A-S-o> O<Esc>
inoremap <A-o> <C-o>o
inoremap <A-S-o> <C-o>O

" quit vim
nnoremap <silent> <Leader>q :wall<Bar>qa<CR>
nnoremap <silent> <LocalLeader>q :qa!<CR>

" select all lines
nnoremap <Leader>A ggVG

" jump to end of line without far reach
nmap <A-a> $
omap <A-a> $
xmap <A-a> $
imap <A-a> <C-o>$

" <Enter> is easier to reach than %
nmap <Enter> %
omap <Enter> %
xmap <Enter> %

" switch buffers
nnoremap <silent> ]b :bnext<CR>
nnoremap <silent> [b :bprev<CR>

" switch tabs
nnoremap <silent> <A-t> :tabedit<CR>
nnoremap <silent> <A-w> :tabclose<CR>
nnoremap <silent> <A-]> :tabnext<CR>
nnoremap <silent> <A-[> :tabprevious<CR>
nnoremap <silent> <A-1> 1gt
nnoremap <silent> <A-2> 2gt
nnoremap <silent> <A-3> 3gt
nnoremap <silent> <A-4> 4gt
nnoremap <silent> <A-5> 5gt
nnoremap <silent> <A-6> 6gt
nnoremap <silent> <A-7> 7gt
nnoremap <silent> <A-8> 8gt
nnoremap <silent> <A-9> 9gt
nnoremap <silent> <A-0> :tablast<CR>

" move up and down while typing
cnoremap <A-j> <Down>
cnoremap <A-k> <Up>
inoremap <A-j> <Down>
inoremap <A-k> <Up>

" scroll the viewport faster
nnoremap <C-e> 3<C-e>
nnoremap <C-y> 3<C-y>

" switch the case of current word
nnoremap <silent> <C-u> mzg~iw`z

" exit terminal mode
tnoremap <silent> <Esc> <C-\><C-n>

" F1 sits too close to F2 (which is rename symbol using LSP)
map <F1> <Nop>
