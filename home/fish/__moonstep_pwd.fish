# Replace $HOME in path with custom texts
# /home/asomeone/p -> ~/p

# /home/abc/def
#   ^segment       ^ last segment
# ^ separator
function __moonstep_pwd
    set -f reset          ( set_color reset )
    set -f seg_color      ( set_color blue )
    set -f last_seg_color ( set_color brblue --bold )
    set -f sep_color      ( set_color blue --dim )

    # Config: replace $HOME with this text.
    set -f replace_home true
    set -f replace_home_text '~'

    set -f pwd ( pwd )
    set -f home_re ( string escape --style regex -- $HOME )

    string match --quiet --regex "^$home_re" "$pwd"
    and set -f is_under_home true

    if [ "$replace_home" = true ]
        string replace \
            --regex "^$home_re" \
            ( string escape --style regex $replace_home_text ) \
            "$pwd" \
            | read --null pwd
    end

    set -f segments \
        ( string split --no-empty "/" -- "$pwd" )
    set -f colored_segments

    set -f separator \
        {$sep_color}"/"{$reset}

    set -f head_segs $segments[1..-2]
    set -f last_seg $segments[-1]

    test ( count $head_segs ) -ne 0
    and for seg in $head_segs
        set --append colored_segments \
            {$seg_color}{$seg}{$reset}
    end

    not test -z "$last_seg"
    and begin
        set --append colored_segments \
            {$last_seg_color}{$last_seg}{$reset}
    end

    set -f colored_pwd \
        ( string join $separator $colored_segments )

    if [ "$is_under_home" != true ]
        set colored_pwd "$separator$colored_pwd"
    end

    set colored_pwd "$colored_pwd$reset"

    printf '%s' "$colored_pwd"

end
