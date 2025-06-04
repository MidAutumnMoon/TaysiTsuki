function __moonstep_prompt

    set -f char "\$>"
    set -f gap " "

    set -f color (
        if [ "$__moonstep_saved_status" = 0 ]
            echo ( set_color blue )
        else
            echo ( set_color red )
        end
    )

    printf "$color%s%s$(set_color reset)" \
        "$char" \
        "$gap"

end
