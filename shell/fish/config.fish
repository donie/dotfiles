set fish_greeting ''
set -gx TERM xterm-256color
set -x LANG en_US.UTF-8
set -x LC_ALL en_US.UTF-8

# title
set -g theme_title_display_process true
set -g theme_title_display_path false
set -g theme_title_display_user true
set -g theme_title_use_abbreviated_path yes

# prompt
set -g __fish_git_prompt_show_informative_status true
set -g __fish_git_prompt_showdirtystate true
set -g __fish_git_prompt_char_stateseparator '|'
set -g __fish_git_prompt_char_dirtystate '*'
set -g __fish_git_prompt_char_cleanstate '✓'
set -g __fish_git_prompt_char_untrackedfiles ' …'
set -g __fish_git_prompt_char_stagedstate '⇢ '
set -g __fish_git_prompt_color_dirtystate yellow
set -g __fish_git_prompt_color_cleanstate green --bold
set -g __fish_git_prompt_color_invalidstate red
set -g __fish_git_prompt_color_branch cyan --dim
set -g __fish_git_prompt_showupstream yes
set -g __fish_git_prompt_char_upstream_prefix ' '
set -g __fish_git_prompt_char_upstream_equal ' '
set -g __fish_git_prompt_char_upstream_ahead '⇡'
set -g __fish_git_prompt_char_upstream_behind '⇣'
set -g __fish_git_prompt_char_upstream_diverged '⇡⇣'

# alias
# detect which `ls` flavor is in use
if ls --color >/dev/null 2>&1

    # GNU `ls`
    set colorflag --color
    export LS_COLORS 'no=00:fi=00:di=01;31:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:'
else
    # macOS `ls`
    set colorflag -G
    export LSCOLORS BxBxhxDxfxhxhxhxhxcxcx
end

# list all files colorized in long format
alias l="ls -lF $colorflag"
alias ll="ls -lF $colorflag"
# list all files colorized in long format, excluding . and ..
alias la="ls -lAF $colorflag"
# always use color output for `ls`
if type -q gls
    alias ls 'gls --color=auto'
else if ls --color=auto &>/dev/null
    alias ls 'ls --color=auto'
else
    alias ls 'ls -G'
end

# always enable colored `grep` output
# note: `GREP_OPTIONS="--color=auto"` is deprecated, hence the alias usage.
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# others
alias df 'df -h'
alias vi nvim
alias vim nvim
alias vimdiff 'nvim -d'
alias so source
type -q bat; and alias cat bat
type -q fd; and alias find fd
type -q tldr; and alias help tldr
type -q htop; and alias top htop
type -q gallery-dl; and alias gdl gallery-dl

# abbreviation
abbr mtr 'sudo mtr'
abbr ncdu 'ncdu --color dark'
abbr ping 'prettyping --nolegend'
abbr brewlog 'brew log --pretty=format:"%h, %aI, %an%n >>%s<<%n" --graph'
abbr ytdlp 'yt-dlp -f "bestvideo[ext=mp4][vcodec^=avc1]+bestaudio[ext=m4a][acodec^=mp4a]/best[ext=mp4]"'
abbr cpwp 'rsync -rv ~/Documents/blogout/draft/public/ ~/Documents/blogout/weblog/'
abbr jkbuild 'jekyll build --source ~/Documents/blogsrc/ --destination ~/Documents/blogout/draft/public/'
abbr jkwatch 'jekyll build --source ~/Documents/blogsrc/ --destination ~/Documents/blogout/draft/public/ --watch'

# last
set -gx EDITOR nvim

# set PATH
fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/sbin
fish_add_path $HOME/go/bin
fish_add_path ~/_runtime/bin
fish_add_path ~/.local/bin
fish_add_path ~/.cargo/bin

## set *utils PATH
if type -q brew
    if not set -q HOMEBREW_PREFIX
        set -l HOMEBREW_PREFIX (brew --prefix)
    end
    for d in $HOMEBREW_PREFIX/opt/*/libexec/gnubin
        fish_add_path $d
    end
end

## set rbnev
status --is-interactive; and rbenv init - fish | source
#function rb --wraps ruby --description 'lazy load rbenv'
#    rbenv init - fish | source
#    functions -e rb  # remove this wrapper
#    ruby $argv
#end

## set uv
# rerun this after uv update
# uv generate-shell-completion fish > ~/.config/fish/completions/uv.fish
# uvx --generate-shell-completion fish > ~/.config/fish/completions/uvx.fish
#if type -q uv
#    uv generate-shell-completion fish | source
#    uvx --generate-shell-completion fish | source
#end

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /Users/donie/.lmstudio/bin
# End of LM Studio CLI section

# Added by Antigravity
fish_add_path /Users/donie/.antigravity/antigravity/bin
