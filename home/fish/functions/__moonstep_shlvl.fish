function __moonstep_shlvl
    set -f reset      ( set_color reset )
    set -f text_color ( set_color bryellow )
    set -f num_color  ( set_color normal )

    # Config
    set -f text      "SHLVL"
    set -f min_level 2

    if [ $SHLVL -lt "$min_level" ]
        return
    end

    printf '%s' \
        "$text_color""[SHLVL ""$num_color""$SHLVL""$reset""$text_color""]""$reset"

end
