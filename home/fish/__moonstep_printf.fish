function __moonstep_printf
    # First argument is always a format string; remaining args are
    # printf arguments.
    #
    # `string collect` strips the single trailing newline that commands
    # like `git branch` emit, and prevents command substitution from
    # splitting multi-line output into separate array elements.
    #
    # N.B. We capture `string collect`'s output via command substitution
    # and re-emit with the `printf` builtin, rather than letting
    # `string collect` write directly to stdout. If an external
    # `string collect` process writes to the function's stdout pipe and
    # then exits, a *later* write (from a subsequent `printf` or another
    # function call) causes any downstream `string collect` reader to
    # insert a spurious `\n` at the process boundary — which corrupts
    # the prompt layout. Routing through the builtin avoids this because
    # no external process touches the stdout pipe.
    #
    # N.B. `string trim --chars "\n"` does NOT work as an alternative:
    # fish does not interpret `\n` as a newline inside `--chars`, so it
    # would trim the literal characters `\` and `n` instead.
    set -l result (printf $argv | string collect)
    printf '%s' "$result"
end
