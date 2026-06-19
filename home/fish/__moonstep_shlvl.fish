set -g __shlvl_color ( set_color normal )

set -g __shlvl_text "SHLVL"
set -g __shlvl_text_color ( set_color bryellow )

set -g __shlvl_min_level 2

function __moonstep_shlvl

    set -f __color_reset ( set_color reset )

    if [ $SHLVL -lt "$__shlvl_min_level" ]
        return
    end

    __moonstep_printf "%s" \
        # colored "[$text"
        {$__shlvl_text_color}\[SHLVL" " \
        # colored $SHLVL
        {$__shlvl_color}$SHLVL{$__color_reset} \
        # colored "]"
        {$__shlvl_text_color}\]{$__color_reset}

end
