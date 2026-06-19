function fish_prompt

    # Add a gap between each prompt
    echo

    __moonstep_pwd
    # printf " "
    __moonstep_vcs

    # Second line
    echo

    __moonstep_prompt

end
