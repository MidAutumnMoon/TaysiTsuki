#
# Async prompt implementation.
#
# Lineage: modified from
# https://github.com/acomagr/fish-async-prompt ; redesigned to follow
# the model used by tide/hydro: a single universal variable per shell
# holds the rendered prompt parts, one background fish per prompt cycle
# renders the *original* prompt functions into it, and the parent
# repaints via `--on-variable`.
#
# Why this shape:
#   * One job + one uvar write per cycle means one repaint — no
#     fan-out, no shared-notifier race.
#   * The previous background job is killed before a new one spawns,
#     so a slow render can't clobber a fresher result.
#   * The child fish does not source this file (guarded by
#     `status is-interactive`), so it autoloads the original
#     `fish_prompt` / `fish_right_prompt` from disk and runs those.
#   * State is passed to the child by interpolation on the `fish -c`
#     line — no stdin deserialization, no `eval set -g $vardata`.
#   * The first prompt is rendered synchronously once (a seed) so the
#     screen is never blank before the first async render lands.
#

status is-interactive || exit 0

# Universal variable holding the rendered prompt parts, indexed in the
# order of $__moonstep_prompt_fns. Universal so the background child can
# write it and the parent's `--on-variable` handler fires on change.
set -g __moonstep_prompt_var __moonstep_prompt_{$fish_pid}

set -g __moonstep_prompt_fns \
    fish_prompt \
    fish_right_prompt

# Render the prompt function(s) synchronously into the uvar. Used once
# for the seed; the helpers read $__moonstep_saved_* which must be set
# by the caller.
function __moonstep_render_into_uvar
    set -l parts
    for fn in $__moonstep_prompt_fns
        # `string collect` keeps multi-line output (e.g. fish_prompt's
        # leading/middle `echo`s) as a single array element instead of
        # splitting on newlines.
        set --append parts ($fn | string collect)
    end
    set -U $__moonstep_prompt_var $parts
end

# Repaint whenever the child writes a fresh result.
function __moonstep_repaint --on-variable $__moonstep_prompt_var
    commandline -f repaint
end

# Entry point: runs on every prompt.
function __moonstep_fire --on-event fish_prompt
    # Capture volatile state before any builtin clobbers $status.
    set -l st $status
    set -l ps $pipestatus
    set -l cd $CMD_DURATION

    # Saved globals are read by the prompt helpers (e.g. __moonstep_prompt).
    set -g __moonstep_saved_status $st
    set -g __moonstep_saved_pipestatus $ps
    set -g __moonstep_saved_cmd_duration $cd

    # One-time seed + hijack on the first prompt.
    if not set -q __moonstep_hijacked
        set -g __moonstep_hijacked
        # Render once with the still-original functions so the first
        # prompt isn't blank while the first async render is in flight.
        __moonstep_render_into_uvar
        # Replace the prompt functions with stubs that just print the
        # cached slice. `%s` avoids re-interpreting prompt content as a
        # format string (paths/branches can contain `%`).
        #
        # `$__moonstep_prompt_var"[$i]"` builds the uvar reference as a
        # plain string (e.g. `__moonstep_prompt_391698[2]`): the index
        # is concatenated *outside* variable-index syntax, otherwise
        # fish would index `__moonstep_prompt_var` itself (a 1-element
        # string) and return empty for any index > 1. Then `\$$ref` in
        # the eval derefs that name at runtime.
        set -l i 0
        for fn in $__moonstep_prompt_fns
            set i (math $i + 1)
            set -l ref $__moonstep_prompt_var"[$i]"
            eval "
                function $fn
                    printf '%s' \$$ref
                end
            "
        end
    end

    # Cancel any in-flight render so it can't overwrite a newer result.
    command kill $__moonstep_last_pid 2>/dev/null

    # Capture the fish binary path once (fish forbids command substitution
    # in command position).
    status fish-path | read -l fish_path

    # Render in a child fish. It does not source this file (the
    # `status is-interactive` guard exits early), so it autoloads and
    # runs the original prompt functions from disk. State is baked into
    # the command string; `$st`/`$ps`/`$cd`/`$__moonstep_prompt_fns`/
    # `$__moonstep_prompt_var` expand here in the parent, while the
    # `\$`-prefixed names are left for the child.
    $fish_path -c "
        set -g __moonstep_saved_status $st
        set -g __moonstep_saved_pipestatus $ps
        set -g __moonstep_saved_cmd_duration $cd
        set -l parts
        for fn in $__moonstep_prompt_fns
            set --append parts (\$fn | string collect)
        end
        set -U $__moonstep_prompt_var \$parts
    " >/dev/null 2>&1 &

    set -g __moonstep_last_pid $last_pid
    disown
end

# Kill the in-flight render and drop the uvar on exit.
function __moonstep_clean --on-event fish_exit
    command kill $__moonstep_last_pid 2>/dev/null
    set -eU $__moonstep_prompt_var
end
