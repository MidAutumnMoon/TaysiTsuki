# Replace $HOME in path with custom texts
# /home/asomeone/p -> ~/p
set -g __pwd_replace_home true
set -g __pwd_replace_home_text "~"

# /home/abc/def
#   ^segment
set -g __pwd_segment_color \
    ( set_color blue )

# /home/abc/def
#            ^ last segment
set -g __pwd_last_segment_color \
    ( set_color brblue --bold )

# /home/abc/def
# ^ separator
set -g __pwd_separator_color \
    ( set_color blue --dim )

function __moonstep_pwd

    set -f pwd ( pwd )

    string match --quiet --regex "^$HOME" "$pwd"
    and set -f is_under_home true

    if [ "$__pwd_replace_home" = true ]
        string replace --regex \
            "^$HOME" "$__pwd_replace_home_text" "$pwd" \
            | read --null pwd
    end

    set -f colored_segments

    set -f segments ( string split "/" "$pwd" )

    for seg in $segments[1..-2]
        test -z "$seg" && continue
        set --append colored_segments \
            "$__pwd_segment_color$seg$(set_color reset)"
    end

    set --append colored_segments \
        "$__pwd_last_segment_color$segments[-1]$( set_color reset )"

    set -f separator \
        "$__pwd_separator_color/$(set_color reset)"

    __moonstep_print ( string join $separator $colored_segments )

end
