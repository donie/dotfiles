"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
filetype off

if system('uname -s') == "Darwin\n"
  " possibly mac
  set clipboard=unnamed
else
  " linux
  set clipboard=unnamedplus
endif
set cmdheight=1
set cursorline
set equalalways
set expandtab
set ffs=unix,dos,mac        " set standard file type
set fileencodings=utf-8,ucs-bom,gb18030,gbk,gb2312,cp936
set guitablabel=%t
set linespace=2
set matchpairs=(:),{:},[:],<:>
set nobackup                " set no backup
set noerrorbells
set nowb
set noswapfile
set number
set numberwidth=4
set nowrap
set shiftwidth=4
set shortmess=aoOtI
set smartcase
" set spell
set t_Co=256
set tabstop=4
set visualbell
set whichwrap=b,s,<,>,[,]
set wildignore+=*/tmp/*,*/venv/*,*/data/*,*/dist/*,*/log/*/,*/logs/*,*.o,*~,*.obj,*/\.git/*,*.pdf,*.zip,*.pyc,*.gz,*.bz,*.tar,*.jpg,*.png,*.gif,*.avi,*.wmv,*.ogg,*.mp3,*.mov
set wildmenu
set foldlevelstart=20

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" plugins
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#begin()

" utilities
Plug 'wincent/command-t'
Plug 'mhinz/vim-startify'
Plug 'mhinz/vim-rfc'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'mbbill/undotree'
Plug 'ntpeters/vim-better-whitespace'
Plug 'scrooloose/nerdtree'
Plug 'mileszs/ack.vim'
Plug 'tpope/vim-commentary'
Plug 'ap/vim-buftabline'
Plug 'ConradIrwin/vim-bracketed-paste'
" Plug 'mkitt/tabline.vim'
" Plug 'fholgado/minibufexpl.vim'

" ruby
Plug 'tpope/vim-rails'
Plug 'tpope/vim-rake'
Plug 'tpope/vim-bundler'
Plug 'tpope/vim-endwise'

" syntax
Plug 'NLKNguyen/c-syntax.vim'
Plug 'pboettch/vim-cmake-syntax'
Plug 'ap/vim-css-color'
Plug 'kchmck/vim-coffee-script'
Plug 'pangloss/vim-javascript'
Plug 'elzr/vim-json'
Plug 'fatih/vim-go'
Plug 'raichoo/haskell-vim'
Plug 'tpope/vim-markdown'
Plug 'hdima/python-syntax'
Plug 'elixir-editors/vim-elixir'

" colorschemes
Plug 'altercation/vim-colors-solarized'
Plug 'NLKNguyen/papercolor-theme'

call plug#end()
