"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Basic Settings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set nocompatible        " be iMproved, required
syntax on              " enable syntax highlighting
set encoding=utf-8     " set encoding to UTF-8 (default was "latin1")

" Interface
set number             " show line numbers
set cursorline        " highlight current line
set showmatch         " highlight matching brackets
set showcmd           " show command in bottom bar
set showmode          " show current mode (insert, visual, etc)
set wildmenu          " visual autocomplete for command menu
set laststatus=2      " always show status line
set ruler             " show cursor position

" Functionality
set autoread          " reload files changed outside vim
set backspace=indent,eol,start  " make backspace work as expected
set hidden            " allow switching buffers without saving
set history=1000      " more command history
set clipboard=unnamed " use system clipboard

" Backup and Swap
set nobackup          " don't create backup files
set noswapfile        " don't create swap files
set nowritebackup     " don't create backup files while editing

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Indentation
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set autoindent        " copy indent from previous line
set smartindent       " smart autoindenting for C-like programs
set expandtab         " use spaces instead of tabs
set tabstop=4        " number of spaces for tab
set shiftwidth=4     " number of spaces for autoindent
set softtabstop=4    " number of spaces for tab while editing

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set incsearch         " search as characters are entered
set hlsearch          " highlight matches
set ignorecase        " ignore case when searching
set smartcase         " ignore case if search pattern is lowercase

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" File Type
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
filetype on           " enable filetype detection
filetype indent on    " enable filetype-specific indenting
filetype plugin on    " enable filetype-specific plugins

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Visual Aids
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set scrolloff=5       " keep 5 lines above/below cursor visible
set colorcolumn=80    " show column for max line length
set list              " show invisible characters

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Performance
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set lazyredraw        " don't redraw while executing macros
set ttyfast           " faster redrawing
set updatetime=300    " faster completion

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Auto Brackets
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
inoremap {      {}<Left>
inoremap {<CR>  {<CR>}<Esc>O
inoremap {{     {
inoremap {}     {}
