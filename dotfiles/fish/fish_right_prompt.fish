function fish_right_prompt

    status is-interactive && return

    set -g __color_reset ( set_color reset )

    __moonstep_shlvl

end
