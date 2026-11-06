function __moonstep_duration
    if not set -q __moonstep_saved_cmd_duration[1]
        return
    end

    # Unit is ms
    set -f min_duration 10000

    if [ "$__moonstep_saved_cmd_duration" -le "$min_duration" ]
        return
    end

    set -f reset (set_color reset)
    set -f color (set_color normal --dim)

    set -f total_s (math "floor($__moonstep_saved_cmd_duration / 1000)")
    set -f h (math "floor($total_s / 3600)")
    set -f m (math "floor(($total_s % 3600) / 60)")
    set -f s (math "$total_s % 60")

    set -f parts
    test "$h" -gt 0; and set --append parts "$h"h
    test "$m" -gt 0; and set --append parts "$m"m
    set --append parts "$s"s

    printf '%s' "$color"(string join ' ' $parts)"$reset"

end
