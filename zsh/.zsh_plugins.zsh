fpath+=( "$HOME/Library/Caches/antidote/github.com/romkatv/powerlevel10k" )
source "$HOME/Library/Caches/antidote/github.com/romkatv/powerlevel10k/powerlevel10k.zsh-theme"
source "$HOME/Library/Caches/antidote/github.com/romkatv/powerlevel10k/powerlevel9k.zsh-theme"
fpath+=( "$HOME/Library/Caches/antidote/github.com/getantidote/use-omz" )
source "$HOME/Library/Caches/antidote/github.com/getantidote/use-omz/use-omz.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib" )
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/async_prompt.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/bzr.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/cli.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/clipboard.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/compfix.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/completion.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/correction.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/diagnostics.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/directories.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/functions.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/git.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/grep.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/history.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/key-bindings.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/misc.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/nvm.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/prompt_info_functions.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/spectrum.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/termsupport.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/theme-and-appearance.zsh"
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/lib/vcs_info.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/git" )
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/git/git.plugin.zsh"
if ! (( $+functions[zsh-defer] )); then
  fpath+=( "$HOME/Library/Caches/antidote/github.com/romkatv/zsh-defer" )
  source "$HOME/Library/Caches/antidote/github.com/romkatv/zsh-defer/zsh-defer.plugin.zsh"
fi
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/github" )
zsh-defer source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/github/github.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/docker" )
zsh-defer source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/docker/docker.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/colored-man-pages" )
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/colored-man-pages/colored-man-pages.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/command-not-found" )
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/command-not-found/command-not-found.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/extract" )
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/extract/extract.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/copybuffer" )
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/copybuffer/copybuffer.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/copypath" )
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/copypath/copypath.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/copyfile" )
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/copyfile/copyfile.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/dirhistory" )
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/dirhistory/dirhistory.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/sudo" )
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/sudo/sudo.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/history" )
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/history/history.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/web-search" )
zsh-defer source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/web-search/web-search.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/fzf" )
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/fzf/fzf.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/alias-finder" )
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/alias-finder/alias-finder.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/aliases" )
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/aliases/aliases.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/MichaelAquilina/zsh-you-should-use" )
source "$HOME/Library/Caches/antidote/github.com/MichaelAquilina/zsh-you-should-use/zsh-you-should-use.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/zsh-users/zsh-autosuggestions" )
source "$HOME/Library/Caches/antidote/github.com/zsh-users/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/zsh-users/zsh-syntax-highlighting" )
source "$HOME/Library/Caches/antidote/github.com/zsh-users/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/zsh-users/zsh-completions" )
source "$HOME/Library/Caches/antidote/github.com/zsh-users/zsh-completions/zsh-completions.plugin.zsh"
fpath+=( "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/brew" )
source "$HOME/Library/Caches/antidote/github.com/ohmyzsh/ohmyzsh/plugins/brew/brew.plugin.zsh"
