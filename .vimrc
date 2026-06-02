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
set tabstop=4
set shiftwidth=4
set softtabstop=4

" Quality of life
set mouse=a
set wildmenu
set nowrap
set backspace=indent,eol,start

" Syntax/filetype
syntax on
filetype plugin indent on

" Easier reload/edit vimrc
nnoremap <leader>ev :e ~/.vimrc<CR>
nnoremap <leader>sv :source ~/.vimrc<CR>

" Clear search highlight with Ctrl+l
nnoremap <C-l> :nohlsearch<CR><C-l>
