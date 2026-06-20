# Display $PWD with each segment colored, the last segment emphasized,
# and known path prefixes replaced with short aliases.
#
# /home/user/Project/foo -> ~/Project/foo  (if $HOME=/home/user)
#                              ^~~~~~ last segment, emphasized
#
# To add a prefix alias, append to BOTH arrays below. List longer
# prefixes first so they win over shorter ones
# (e.g. /home/user/Project before /home/user).

function __moonstep_pwd
    # Prefix -> alias mappings (array). First match wins, so order longest-first.
    # Add new mapping like:
    # set -f replace_prefixes $HOME $HOME/Project
    # set -f replace_aliases  '~'   'Project'
    set -f replace_prefixes $HOME
    set -f replace_aliases  '~'

    set -f reset          (set_color reset)
    set -f seg_color      (set_color blue)
    set -f last_seg_color (set_color brblue --bold)
    set -f sep_color      (set_color blue --dim)

    set -f pwd (pwd)

    # Apply the first matching prefix replacement, if any.
    for i in ( seq ( count $replace_prefixes ) )
        set -f prefix_re ( string escape --style regex -- $replace_prefixes[$i] )
        if string match --quiet --regex "^$prefix_re" -- "$pwd"
            set pwd ( string replace --regex "^$prefix_re" $replace_aliases[$i] -- "$pwd" )
            break
        end
    end

    # Split into segments. If the path still starts with `/` it's an
    # untouched absolute path and gets a leading separator; aliased
    # paths (e.g. `~`, `NAS`) have already consumed the leading slash.
    set -f segments ( string split --no-empty "/" -- "$pwd" )
    set -f leading_sep
    if string match --quiet --regex '^/' -- "$pwd"
        set leading_sep "$sep_color/$reset"
    end

    # Color head segments with seg_color, last segment with last_seg_color.
    set -f colored_segments
    for seg in $segments[..-2]
        set --append colored_segments "$seg_color$seg$reset"
    end
    # `$segments[-1]` would error on an empty array (root `/`); guard.
    if set -q segments[1]
        set --append colored_segments "$last_seg_color$segments[-1]$reset"
    end

    set -f separator "$sep_color/$reset"
    set -f colored_pwd ( string join -- $separator $colored_segments )

    printf '%s ' "$leading_sep$colored_pwd$reset"

end
