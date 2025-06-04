function fish_prompt

    status is-interactive && return

    set -g __color_reset ( set_color reset )

    # Add a gap between each prompt
    echo

    __moonstep_pwd

    # Second line
    echo

    __moonstep_prompt

end

