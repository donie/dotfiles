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
