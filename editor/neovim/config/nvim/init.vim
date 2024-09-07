set smartcase

let g:lightline = {
      \ 'colorscheme': 'PaperColor',
      \ }
colorscheme one
let theme=getenv('DOTTY_THEME')
if theme == 'dark'
    set background=dark
else
    set background=light
endif


" Enable global clipboard
set clipboard+=unnamedplus

" Disable swapfile and backup
set nobackup
set noswapfile

" set relativenumber
set number
set hidden
set showmatch
set comments=sl:/*,mb:\ *,elx:\ */

" Search
set incsearch
set hls

" Code
syntax enable

imap jk <Esc>

" black hole register
vmap <backspace> "_d
vmap <del> "_d

" Allow backspace and cursor keys to cross line boundaries
set whichwrap+=<,>,h,l

" ============================================================================
" emacs keymaping for cursor movement
" You have to unbind C-g before it works
" ============================================================================
map <c-c><c-c> <Esc>:wqa<CR>
map <c-c><c-k> <Esc>:qa!<CR>
nmap <c-g> <Esc>
vmap <c-g> <Esc>
imap <c-g> <Esc>a
cnoremap <C-g> <Esc>
nmap <c-a> ^
nmap <c-e> $
vmap <c-a> ^
vmap <c-e> $
imap <c-e> <Esc>A
imap <c-a> <Esc>I
imap <c-d> <del>
imap <c-k> <Esc><right>Da
inoremap <c-f> <right>
inoremap <c-b> <left>
inoremap <c-p> <up>
inoremap <c-n> <down>
" command line
cnoremap <C-a> <Home>
cnoremap <C-e> <End>

" Macos keybindings
nmap <A-s> :wa<cr>
vmap <A-s> :wa<cr>
imap <A-s> <Esc>:wa<cr>a

" Tmux navigator
let g:tmux_navigator_no_mappings = 1
map <c-t>h :TmuxNavigateLeft<CR>
map <c-t>l :TmuxNavigateRight<CR>
map <c-t>k :TmuxNavigateUp<CR>
map <c-t>j :TmuxNavigateDown<CR>
map <c-t>\ :TmuxNavigatePrevious<CR>
map <c-t><c-h> :TmuxNavigateLeft<CR>
map <c-t><c-l> :TmuxNavigateRight<CR>
map <c-t><c-k> :TmuxNavigateUp<CR>
map <c-t><c-j> :TmuxNavigateDown<CR>
map <c-t><c-\> :TmuxNavigatePrevious<CR>
