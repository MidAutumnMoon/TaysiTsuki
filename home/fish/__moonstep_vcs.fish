# TODO: implement merge/rebase indicator

set -g __vcs_staged_text '+'
set -g __vcs_staged_color ( set_color brgreen )

set -g __vcs_dirty_text '~'
set -g __vcs_dirty_color ( set_color bryellow )

set -g __vcs_conflict_text '!!'
set -g __vcs_conflict_color ( set_color brred )

set -g __vcs_untracked_text '?'
set -g __vcs_untracked_color ( set_color brblue )

set -g __vcs_stash_text 'Stash '
set -g __vcs_stash_color ( set_color brmagenta )

set -g __vcs_ahead_text 'Ahead '
set -g __vcs_ahead_color ( set_color cyan )
set -g __vcs_behind_text 'Behind '
set -g __vcs_behind_color ( set_color cyan )

set -g __vcs_git_color ( set_color purple )

set -g __vcs_git_branch_color ( set_color bryellow )

set -g __vcs_jj_text "jj"
set -g __vcs_jj_text_color ( set_color purple )

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
    printf '%s' \
        "$__vcs_git_branch_color""$branch"
end

# Based on "_tide_item_git.fish" from tide.fish
function __moonstep_git_status
    set -f __color_reset ( set_color reset )
    set -f git_cmd \
        git --no-optional-locks

    set -f git_status (
        command $git_cmd status --porcelain=v1 2>/dev/null
    )

    set -f behind_ahead (
        git rev-list --count \
            --left-right "@{upstream}...HEAD" \
            2>/dev/null \
            # tab, not space
            | string split --no-empty \t )

    # Build (name, count) pairs for each indicator.
    # N.B. In git's porcelain v1 output, "." means whitespace:
    #   "M"  -> staged
    #   " M" -> dirty
    set -f pairs \
        "stash"     ( command $git_cmd stash list 2>/dev/null | count ) \
        "conflict"  ( string match -r '^(DD|AU|UD|UA|DU|AA|UU)' $git_status | count ) \
        "staged"    ( string match -r '^[ADMR]' $git_status | count ) \
        "dirty"     ( string match -r '^.[ADMR]' $git_status | count ) \
        "untracked" ( string match -r '^\?\?' $git_status | count )

    if test ( count $behind_ahead ) -ge 1
        set --append pairs "behind" $behind_ahead[1]
    end
    if test ( count $behind_ahead ) -ge 2
        set --append pairs "ahead" $behind_ahead[2]
    end

    set -f rendered
    for i in ( seq 1 2 ( count $pairs ) )
        set -f name $pairs[$i]
        set -f cnt  $pairs[( math $i + 1 )]
        test -z "$cnt"; and continue
        test "$cnt" -eq 0; and continue
        set -f text_var  "__vcs_$name""_text"
        set -f color_var "__vcs_$name""_color"
        set --append rendered \
            ( printf '%s' "$$color_var$$text_var$cnt$__color_reset" \
                | string collect )
    end

    printf '%s' ( string join " " $rendered )

end

#
# Jujutsu implementation
#

function __moonstep_jujutsu
    printf '%s' \
        "$__vcs_jj_text_color""jujutsu""(unimplemented)"
end
