function __moonstep_printf
    # First argument is always a format string; remaining args are
    # printf arguments. `string collect` strips the single trailing
    # newline that commands like `git branch` emit, and collects
    # multi-line output into one string. (We deliberately do NOT trim
    # spaces — components may want leading/trailing whitespace.)
    #
    # N.B. `string trim --chars "\n"` does NOT work here: fish does
    # not interpret `\n` as a newline inside `--chars`, so it would
    # trim the literal characters `\` and `n` instead.
    printf $argv | string collect
end
