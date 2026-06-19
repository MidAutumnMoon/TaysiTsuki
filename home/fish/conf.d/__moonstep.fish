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

# Idempotency guard: re-sourcing this file (dev iteration, config
# reload) would otherwise re-register every `--on-event`/`--on-variable`
# handler under a fresh function definition, firing each one twice per
# cycle. Fish dedups function bodies but not event bindings.
set -q __moonstep_loaded; and exit 0
set -g __moonstep_loaded

# Universal variable holding the rendered prompt parts, indexed in the
# order of $__moonstep_prompt_fns. Universal so the background child can
# write it and the parent's `--on-variable` handler fires on change.
set -g __moonstep_prompt_var __moonstep_prompt_{$fish_pid}

set -g __moonstep_prompt_fns \
    fish_prompt \
    fish_right_prompt

# Generation counter (per-shell uvar) so a slow background render can
# detect that it's been superseded and abort before writing a stale
# result. `command kill` on the previous child is async; this is the
# race-free backstop.
set -g __moonstep_gen_var __moonstep_prompt_gen_{$fish_pid}
set -g __moonstep_gen 0
set -U $__moonstep_gen_var 0

# Capture the fish binary once at load (fish forbids command
# substitution in command position); reused on every prompt.
status fish-path | read -g __moonstep_fish_path

# Sweep orphaned uvars from crashed/killed previous sessions. Live
# sessions are skipped — `kill -0` succeeds for them. (`kill -0` only
# probes liveness; it does not send a signal.)
for v in (set -Un | string match "__moonstep_prompt_*")
    set -l pid (string match -r '[0-9]+$' $v)
    test -z "$pid"; and continue
    if not kill -0 $pid 2>/dev/null
        set -eU $v
    end
end

# Render the prompt function(s) synchronously into the uvar. Used once
# for the seed; the helpers read $__moonstep_saved_* which must be set
# by the caller.
function __moonstep_render_into_uvar
    set -l parts
    for fn in $__moonstep_prompt_fns
        # `string collect --no-trim-newlines` keeps multi-line output
        # (e.g. fish_prompt's leading/middle `echo`s) as a single array
        # element instead of splitting on newlines, and preserves any
        # trailing newlines verbatim (default trims one).
        set --append parts ($fn | string collect --no-trim-newlines)
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
        #
        # Keep a copy of the original under `__moonstep_orig_<fn>` so
        # the session can recover if something goes wrong with the hijack
        # (e.g. via `functions -c __moonstep_orig_fish_prompt fish_prompt`).
        set -l i 0
        for fn in $__moonstep_prompt_fns
            functions -c $fn __moonstep_orig_$fn
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
    if set -q __moonstep_last_pid
        command kill $__moonstep_last_pid 2>/dev/null
    end

    # Bump the generation counter *before* spawning so that even if the
    # kill above is delayed, a stale child can still detect it has been
    # superseded and abort its write.
    set -g __moonstep_gen (math $__moonstep_gen + 1)
    set -U $__moonstep_gen_var $__moonstep_gen

    # Render in a child fish. It does not source this file (the
    # `status is-interactive` guard exits early), so it autoloads and
    # runs the original prompt functions from disk. State is baked into
    # the command string; `$st`/`$ps`/`$cd`/`$__moonstep_prompt_fns`/
    # `$__moonstep_prompt_var` expand here in the parent, while the
    # `\$`-prefixed names are left for the child.
    $__moonstep_fish_path -c "
        set -g __moonstep_saved_status $st
        set -g __moonstep_saved_pipestatus $ps
        set -g __moonstep_saved_cmd_duration $cd
        set -l parts
        for fn in $__moonstep_prompt_fns
            set --append parts (\$fn | string collect --no-trim-newlines)
        end
        # Abort if a newer spawn has superseded us — prevents a slow
        # child from clobbering a fresher result. `\$$__moonstep_gen_var`
        # double-derefs: parent expands the var *name* (e.g.
        # `__moonstep_prompt_gen_391698`), child reads its *value*.
        test \"$__moonstep_gen\" = \"\$$__moonstep_gen_var\"; or exit
        set -U $__moonstep_prompt_var \$parts
    " >/dev/null &

    set -g __moonstep_last_pid $last_pid
    disown
end

# Kill the in-flight render and drop our uvars on exit.
function __moonstep_clean --on-event fish_exit
    command kill $__moonstep_last_pid 2>/dev/null
    set -eU $__moonstep_prompt_var
    set -eU $__moonstep_gen_var
end
