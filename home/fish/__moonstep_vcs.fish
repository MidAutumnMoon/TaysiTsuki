# TODO: implement merge/rebase indicator

function __moonstep_vcs

    # TODO: prefer jujutsu if implemented
    if command git rev-parse --absolute-git-dir 2>/dev/null >/dev/null
        __moonstep_git
    end

end

#
# Git implementation
#

function __moonstep_git

    # branch — output flows directly to stdout
    __moonstep_git_branch

    # various status indicators
    #
    # N.B. use `read -l` (newline-delimited), NOT `read -lz`: the `-z`
    # (NUL-delimited) mode appends a spurious trailing newline to the
    # captured value when reading from a function pipe, which would
    # push the status onto a new line.
    __moonstep_git_status | read -l status_output
    test -n "$status_output"
    and printf ' %s' $status_output

end

function __moonstep_git_branch
    # `read -f` (not `-fz`): strips git's trailing newline at the source.
    # See the note in __moonstep_git for why `-z` is a footgun here.
    command git branch --show-current 2>/dev/null \
        | read -f branch
    printf '%s' ( set_color bryellow )"$branch"
end

# Renders the git status indicators (stash/conflict/staged/dirty/
# untracked/behind/ahead) joined by spaces.
#
# Based on "_tide_item_git.fish" from tide.fish.
#
# Each indicator is a self-contained block: color, text, and the count
# logic live together. This replaces the earlier dynamic-lookup design
# (16 config vars + `$$var` double-deref) which produced most of the
# line noise in this file.
#
# N.B. In git's porcelain v1 output, "." means whitespace:
#   "M"  -> staged
#   " M" -> dirty
function __moonstep_git_status
    set -f reset ( set_color reset )
    set -f git_cmd git --no-optional-locks

    set -f git_status (
        command $git_cmd status --porcelain=v1 2>/dev/null
    )

    set -f behind_ahead (
        git rev-list --count \
            --left-right "@{upstream}...HEAD" \
            2>/dev/null \
            # tab, not space
            | string split --no-empty \t )

    set -f rendered

    # stash
    set -l n ( command $git_cmd stash list 2>/dev/null | count )
    test "$n" -gt 0
    and set --append rendered ( set_color brmagenta )"Stash $n$reset"

    # conflict (all unmerged states)
    set -l n ( string match -r '^(DD|AU|UD|UA|DU|AA|UU)' $git_status | count )
    test "$n" -gt 0
    and set --append rendered ( set_color brred )"!!$n$reset"

    # staged
    set -l n ( string match -r '^[ADMR]' $git_status | count )
    test "$n" -gt 0
    and set --append rendered ( set_color brgreen )"+$n$reset"

    # dirty
    set -l n ( string match -r '^.[ADMR]' $git_status | count )
    test "$n" -gt 0
    and set --append rendered ( set_color bryellow )"~$n$reset"

    # untracked
    set -l n ( string match -r '^\?\?' $git_status | count )
    test "$n" -gt 0
    and set --append rendered ( set_color brblue )"?$n$reset"

    # behind / ahead
    if test ( count $behind_ahead ) -ge 1
        set -l n $behind_ahead[1]
        test "$n" -gt 0
        and set --append rendered ( set_color cyan )"Behind $n$reset"
    end
    if test ( count $behind_ahead ) -ge 2
        set -l n $behind_ahead[2]
        test "$n" -gt 0
        and set --append rendered ( set_color cyan )"Ahead $n$reset"
    end

    printf '%s' ( string join ' ' $rendered )

end

#
# Jujutsu implementation
#

function __moonstep_jujutsu
    printf '%s' \
        ( set_color purple )"jujutsu""(unimplemented)"
end
