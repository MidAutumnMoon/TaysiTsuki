" Bundled ftplugin/nix.vim is not that good.
"let b:did_ftplugin = 1

setlocal tabstop=4
setlocal softtabstop=4

" automatically insert comment leader
setlocal formatoptions+=ro

" Supports for "#" and "/**/" comments
setlocal comments=b:#,sf0:/*,mb:\ ,ex-1l:*/
setlocal commentstring=#\ %s
