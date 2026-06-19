# Background renderer, autoloaded and called by the child fish spawned
# in __moonstep_fire. Reads $__moonstep_saved_* (set inline by the
# parent's `fish -c` string before calling us) and the original prompt
# functions (autoloaded from the functions/ directory).
#
# argv:
#   $1     prompt uvar name to write the rendered parts into
#   $2     generation uvar name to check for supersession
#   $3     generation value this render represents
#   $4..   prompt function names to call, in uvar-index order
function __moonstep_render
    set -l prompt_var $argv[1]
    set -l gen_var    $argv[2]
    set -l my_gen     $argv[3]
    set -l fns        $argv[4..]

    set -l parts
    for fn in $fns
        # `string collect --no-trim-newlines` keeps multi-line output
        # (e.g. fish_prompt's leading/middle `echo`s) as a single array
        # element and preserves trailing newlines verbatim.
        set --append parts ($fn | string collect --no-trim-newlines)
    end

    # Abort if a newer spawn has superseded us — prevents a slow child
    # from clobbering a fresher result. `$$gen_var` double-derefs: the
    # var *name* → its current universal-variable value.
    test "$my_gen" = "$$gen_var"; or exit

    set -U $prompt_var $parts
end
