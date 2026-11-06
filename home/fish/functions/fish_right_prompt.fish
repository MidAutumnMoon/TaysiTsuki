function fish_right_prompt

    set -l parts (__moonstep_duration) (__moonstep_shlvl)

    test -n "$parts"; and string join ' ' $parts

end
