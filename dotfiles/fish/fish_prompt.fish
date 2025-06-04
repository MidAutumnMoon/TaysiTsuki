function fish_prompt

    status is-interactive && return

    # Add a gap between each prompt
    echo

    __moonstep_pwd

    # Second line
    echo

    __moonstep_prompt

end

