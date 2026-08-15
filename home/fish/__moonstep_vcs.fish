# TODO: implement merge/rebase indicator

function __moonstep_vcs

    # Prefer jujutsu: a colocated repo has both .jj/ and .git/, but jj
    # is the source of truth in that setup. A standalone git repo (no
    # .jj/) falls through to the git path.
    if command jj root --ignore-working-copy 2>/dev/null >/dev/null
        __moonstep_jujutsu
    else if command git rev-parse --absolute-git-dir 2>/dev/null >/dev/null
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
    printf '%s' (set_color bryellow)"$branch"
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
    set -f reset (set_color reset)
    set -f git_cmd git --no-optional-locks

    set -f git_status (
        command $git_cmd status --porcelain=v1 2>/dev/null
    )

    set -f behind_ahead (
        git rev-list --count \
            --left-right "@{upstream}...HEAD" \
            2>/dev/null \
            # tab, not space
            | string split --no-empty \t)

    set -f rendered

    # stash
    set -l n (command $git_cmd stash list 2>/dev/null | count)
    test "$n" -gt 0
    and set --append rendered (set_color brmagenta)"Stash $n$reset"

    # conflict (all unmerged states)
    set -l n (string match -r '^(DD|AU|UD|UA|DU|AA|UU)' $git_status | count)
    test "$n" -gt 0
    and set --append rendered (set_color brred)"!!$n$reset"

    # staged
    set -l n (string match -r '^[ADMR]' $git_status | count)
    test "$n" -gt 0
    and set --append rendered (set_color brgreen)"+$n$reset"

    # dirty
    set -l n (string match -r '^.[ADMR]' $git_status | count)
    test "$n" -gt 0
    and set --append rendered (set_color bryellow)"~$n$reset"

    # untracked
    set -l n (string match -r '^\?\?' $git_status | count)
    test "$n" -gt 0
    and set --append rendered (set_color brblue)"?$n$reset"

    # behind / ahead
    if test (count $behind_ahead) -ge 1
        set -l n $behind_ahead[1]
        test "$n" -gt 0
        and set --append rendered (set_color cyan)"Behind $n$reset"
    end
    if test (count $behind_ahead) -ge 2
        set -l n $behind_ahead[2]
        test "$n" -gt 0
        and set --append rendered (set_color cyan)"Ahead $n$reset"
    end

    printf '%s' (string join ' ' $rendered)

end

#
# Jujutsu implementation
#
# jj's template language emits all prompt data in a single `jj log`
# call, so unlike git we need just one subprocess. __moonstep_jj_query
# selects @, trunk(), and the commits between them, then a template
# tags each line with its role (AT/AHEAD/BEHIND/TRUNK) and emits
# tab-separated fields.
#
# `--ignore-working-copy` prevents the prompt from snapshotting the
# working copy or modifying repo state. Output is `--color=never`;
# colors are applied here to match the moonstep palette.
#
# Field layout (tab-separated, role-prefixed):
#   AT      change_id  bookmarks  conflict  divergent  empty  immutable  modified  added  deleted  conflicted_files
#   TRUNK   bookmark_names  is_root
#   AHEAD   (no fields — count = number of AHEAD lines)
#   BEHIND  (no fields — count = number of BEHIND lines)

function __moonstep_jujutsu

    # change ID / bookmarks — output flows directly to stdout
    __moonstep_jj_id

    # various status indicators
    __moonstep_jj_status | read -l status_output
    test -n "$status_output"
    and printf ' %s' $status_output

end

# Emits the change ID (or bookmarks if present) for the @ commit,
# plus ahead/behind counts relative to trunk. Both are derived from a
# single `jj log` call whose output is cached in `$__moonstep_jj_raw`
# (a global, because `__moonstep_jj_status` — a sibling function —
# can't see a `-f` local) and shared to avoid a second invocation.
function __moonstep_jj_id
    __moonstep_jj_query | read -lz raw
    set -g __moonstep_jj_raw $raw

    set -f reset (set_color reset)

    set -f change_id
    set -f bookmarks
    set -f ahead 0
    set -f behind 0

    # `read -lz` captured the multi-line output as a single string;
    # split it into lines for iteration.
    for line in (string split --no-empty \n -- $__moonstep_jj_raw)
        set -f parts (string split \t -- $line)
        switch $parts[1]
            case AT
                set change_id $parts[2]
                set bookmarks $parts[3]
            case AHEAD
                set ahead (math $ahead + 1)
            case BEHIND
                set behind (math $behind + 1)
        end
    end

    # Show bookmarks if any, otherwise the change ID. This matches the
    # consensus from fish-shell#11183: bookmarks are aliases for the
    # current change, so they subsume the change ID when present.
    if test -n "$bookmarks"
        printf '%s' (set_color bryellow)"$bookmarks"
    else
        printf '%s' (set_color bryellow)"$change_id"
    end

    # ahead / behind relative to trunk
    test "$ahead" -gt 0
    and printf ' %s' (set_color cyan)"Ahead $ahead$reset"
    test "$behind" -gt 0
    and printf ' %s' (set_color cyan)"Behind $behind$reset"

end

# Renders the jj status indicators (conflict/divergent/empty/immutable/
# modified/added/deleted) joined by spaces.
#
# Reads the cached query from `$__moonstep_jj_raw` (populated by
# __moonstep_jj_id if it ran first). If empty (e.g. called directly),
# runs the query itself.
function __moonstep_jj_status
    set -f reset (set_color reset)

    if not set -q __moonstep_jj_raw[1]
        __moonstep_jj_query | read -lz raw
        set __moonstep_jj_raw $raw
    end

    set -f conflict 0
    set -f divergent 0
    set -f empty 0
    set -f immutable 0
    set -f modified 0
    set -f added 0
    set -f deleted 0
    set -f conflicted_files 0

    for line in (string split --no-empty \n -- $__moonstep_jj_raw)
        set -f parts (string split \t -- $line)
        if test "$parts[1]" = AT
            # AT fields: role change_id bookmarks conflict divergent empty immutable modified added deleted conflicted_files
            test "$parts[4]" = 1; and set conflict 1
            test "$parts[5]" = 1; and set divergent 1
            test "$parts[6]" = 1; and set empty 1
            test "$parts[7]" = 1; and set immutable 1
            set modified $parts[8]
            set added $parts[9]
            set deleted $parts[10]
            set conflicted_files $parts[11]
            break
        end
    end

    set -f rendered

    test "$conflict" -eq 1
    and set --append rendered (set_color brred)"!!$reset"
    # conflicted files (only if there are conflicts and a count > 0)
    test "$conflict" -eq 1; and test "$conflicted_files" -gt 0
    and set --append rendered (set_color brred)"C$conflicted_files$reset"

    # divergent (same change ID, multiple commits)
    test "$divergent" -eq 1
    and set --append rendered (set_color brred)"?$reset"

    # empty (no file changes in @)
    test "$empty" -eq 1
    and set --append rendered (set_color brblack)"(empty)$reset"

    # immutable (on a commit that can't be rewritten)
    test "$immutable" -eq 1
    and set --append rendered (set_color brblue)"◆$reset"

    test "$modified" -gt 0
    and set --append rendered (set_color bryellow)"~$modified$reset"

    test "$added" -gt 0
    and set --append rendered (set_color brgreen)"+$added$reset"

    test "$deleted" -gt 0
    and set --append rendered (set_color brred)"-$deleted$reset"

    printf '%s' (string join ' ' $rendered)

end

# Runs the combined jj log query (see field layout above) and writes
# the raw output to stdout. Called once per prompt cycle; the result
# is cached by __moonstep_jj_id.
function __moonstep_jj_query
    # `concat` (not `separate`) preserves empty fields — `separate`
    # collapses empty middle arguments, losing tab boundaries and
    # shifting all subsequent field indices.
    command jj log --no-graph --ignore-working-copy --no-pager \
        --color=never \
        -r '@ | trunk() | trunk()..@ | (::trunk() & ~::@)' \
        -T '
            if(self.contained_in("@"),
                concat("AT",
                    "\t", change_id.shortest(),
                    "\t", local_bookmarks.join(","),
                    "\t", if(conflict, "1", "0"),
                    "\t", if(divergent, "1", "0"),
                    "\t", if(empty, "1", "0"),
                    "\t", if(immutable, "1", "0"),
                    "\t", self.diff().files().filter(|f| f.status_char() == "M").len(),
                    "\t", self.diff().files().filter(|f| f.status_char() == "A").len(),
                    "\t", self.diff().files().filter(|f| f.status_char() == "D").len(),
                    "\t", self.conflicted_files().len()
                ),
                if(self.contained_in("trunk()"),
                    concat("TRUNK",
                        "\t", self.bookmarks().map(|b| b.name()).join(","),
                        "\t", if(self.root(), "1", "0")
                    ),
                    if(self.contained_in("::trunk() & ~::@"),
                        "BEHIND",
                        "AHEAD"
                    )
                )
            ) ++ "\n"
        ' 2>/dev/null
end
