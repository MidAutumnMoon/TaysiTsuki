# Replace $HOME in path with custom texts
# /home/asomeone/p -> ~/p
set -g __pwd_replace_home true

set -g __pwd_replace_home_text '~'

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

    set -f __color_reset ( set_color reset )

    set -f pwd ( pwd )

    string match --quiet --regex "^$HOME" "$pwd"
    and set -f is_under_home true

    if [ "$__pwd_replace_home" = true ]
        string replace \
            --regex "^$HOME" \
            ( string escape --style regex $__pwd_replace_home_text ) \
            "$pwd" \
            | read --null pwd
    end

    set -f segments \
        ( string split --no-empty "/" -- "$pwd" )
    set -f colored_segments

    set -f separator \
        {$__pwd_separator_color}"/"{$__color_reset}

    set -f head_segs $segments[1..-2]
    set -f last_seg $segments[-1]

    test ( count $head_segs ) -ne 0
    and for seg in $head_segs
        set --append colored_segments \
            {$__pwd_segment_color}{$seg}{$__color_reset}
    end

    not test -z "$last_seg"
    and begin
        set --append colored_segments \
            {$__pwd_last_segment_color}{$last_seg}{$__color_reset}
    end

    set -f colored_pwd \
        ( string join $separator $colored_segments )

    if [ "$is_under_home" != true ]
        set colored_pwd "$separator$colored_pwd"
    end

    set colored_pwd "$colored_pwd$__color_reset"

    __moonstep_printf "$colored_pwd"

end
