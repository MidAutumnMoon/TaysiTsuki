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
    if command git rev-parse --absolute-git-dir \
        2>/dev/null | read -l git_dir

        __moonstep_git
    end

end

#
# Git implementation
#

function __moonstep_git --no-scope-shadowing

    command git rev-parse --absolute-git-dir 2>/dev/null \
        | read -f git_dir

    # # colored "["
    # printf "$__vcs_git_color""[""$__color_reset"

    # branch
    begin
        printf ( __moonstep_git_branch "$git_branch" )
    end

    # various status indicator
    begin
        __moonstep_git_status | read -lz status_output
        test -n "$status_output"
        and printf " $status_output" # add a spacer
    end

    # # closing "]"
    # printf "$__vcs_git_color""]""$__color_reset"

end

function __moonstep_git_branch
    command git branch --show-current 2>/dev/null \
        | read -fz branch
    __moonstep_printf "%s" \
        "$__vcs_git_branch_color""$branch"
end

# Based on "_tide_item_git.fish" from tide.fish
function __moonstep_git_status
    set -f git_cmd \
        git --no-optional-locks

    set -f rendered

    function _ren -a name count --no-scope-shadowing
        test -z "$name" && return
        test -z "$count" && return
        test "$count" -eq 0 && return
        set -f text_var "__vcs_""$name""_text"
        set -f color_var "__vcs_""$name""_color"
        printf "%s" \
            "$$color_var$$text_var$count$__color_reset" \
            | read -zf _output
        set --append rendered "$_output"
        set --erase _output
    end

    _ren "stash" ( command $git_cmd stash list 2>/dev/null | count )

    set -f git_status (
        command $git_cmd status --porcelain=v1 2>/dev/null
    )

    _ren "conflict" ( string match -r '^UU' $git_status | count )
    # N.B. "." means whitespace. In git's output
    # "M" -> staged
    # " M" -> dirty
    _ren "staged" ( string match -r '^[ADMR]' $git_status | count )
    _ren "dirty" ( string match -r '^.[ADMR]' $git_status | count )
    _ren "untracked" ( string match -r '^\?\?' $git_status | count )

    set -f behind_ahead (
        git rev-list --count \
            --left-right "@{upstream}...HEAD" \
            2>/dev/null \
            # tab, not space
            | string split --no-empty \t )

    _ren "behind" $behind_ahead[1]
    _ren "ahead" $behind_ahead[2]

    printf "%s" ( string join " " $rendered )

    functions --erase _ren
end

#
# Jujutsu implementation
#

function __moonstep_jujutsu --no-scope-shadowing
    __moonstep_printf "$__vcs_jj_text_color"jujutsu"(unimplemented)"
end
