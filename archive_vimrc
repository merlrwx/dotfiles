" ~/.vimrc

set nocompatible

" Show useful info
set number
set ruler
set showcmd
set showmode

" Searching
set hlsearch
set incsearch
set ignorecase
set smartcase

" Indentation
set autoindent
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2

" Highlight trailing whitespace in all files
autocmd BufRead,BufNewFile * match Error /\s\+$/

" Quality of life
set mouse=a
set wildmenu
set nowrap
set backspace=indent,eol,start

" Syntax/filetype
syntax on
filetype plugin indent on

" Ensure Vim uses filetype plugins
filetype plugin on

" Easier reload/edit vimrc
nnoremap <leader>ev :e ~/.vimrc<CR>
nnoremap <leader>sv :source ~/.vimrc<CR>

" Clear search highlight with Ctrl+l
nnoremap <C-l> :nohlsearch<CR><C-l>
