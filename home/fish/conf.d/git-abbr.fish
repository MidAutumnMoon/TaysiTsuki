# Based on https://github.com/jhillyerd/plugin-git

function git_abbr
    abbr -ag "g$argv[1]" "git $argv[2]"
end

git_abbr "a" "add"
git_abbr "aa" "add --all --intent-to-add"
git_abbr "aa!" "add --all"

git_abbr "b" "branch -vv"
git_abbr "ba" "branch -av"

git_abbr "c" "commit -v"
git_abbr "c!" "commit -v --amend"
git_abbr "ca" "commit -v -a"
git_abbr "ca!" "commit -v -a --amend"
git_abbr "cm" "commit -m"
git_abbr "cam" "commit -a -m"

# intentionally to be this long
git_abbr "cherry" "cherry-pick"
git_abbr "cherryc" "cherry-pick --continue"
git_abbr "cherrya" "cherry-pick --abort"

git_abbr "clean" "clean -di"
git_abbr "clean!" "clean -dix"
abbr -ag "gclean!!" "git reset --hard && git clean -dfx"

git_abbr "cl" "clone"
git_abbr "cl!" "clone --depth 1"

git_abbr "co" "checkout"

git_abbr "d" "diff"
git_abbr "dc" "diff --cached"
git_abbr "ds" "diff --stat"
git_abbr "dsc" "diff --stat --cached"

git_abbr "f" "fetch --all --prune"

git_abbr "lo" "log --oneline --decorate --color"
git_abbr "lo!" "log --oneline --decorate --color --graph"
git_abbr "loo" "log --pretty=format:'%C(yellow)%h %Cred%ad %Cblue%an%Cgreen%d %Creset%s' --date=short"

git_abbr "m" "merge"

git_abbr "p" "push"
git_abbr "p!" "push --force-with-lease"

git_abbr "l" "pull"

git_abbr "rb" "rebase"
git_abbr "rba" "rebase --abort"
git_abbr "rbc" "rebase --continue"
git_abbr "rbi" "rebase --interactive"

git_abbr "rs" "restore"
git_abbr "rss" "restore --source"

git_abbr "rst" "reset"
git_abbr "rst!" "reset --hard"

git_abbr "s" "status --short"

git_abbr "sh" "show --ext-diff"

git_abbr "sta" "stash"
git_abbr "stap" "stash pop"
git_abbr "stas" "stash show --text"

git_abbr "sw" "switch"
git_abbr "swc" "switch --create"

# for fun
abbr -ag gcount "git shortlog -sn"

functions --erase git_abbr

# vim: nowrap:
