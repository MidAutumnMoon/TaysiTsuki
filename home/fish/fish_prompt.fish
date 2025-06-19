function fish_prompt

    set -g __color_reset ( set_color reset )

    # Add a gap between each prompt
    echo

    __moonstep_pwd
    # printf " "
    __moonstep_vcs

    # Second line
    echo

    __moonstep_prompt

end

