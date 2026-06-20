function __moonstep_prompt
    set -f reset   ( set_color reset )
    set -f ok_color   ( set_color blue )
    set -f err_color  ( set_color red )

    # Config
    set -f text_ok  '$'
    set -f text_err '$'
    set -f input_text '>'

    if [ "$__moonstep_saved_status" = 0 ]
        set -f text "$text_ok"
        set -f color "$ok_color"
    else
        set -f text "$text_err"
        set -f color "$err_color"
        set -f error_text "($__moonstep_saved_status)"
    end

    printf \
        "$color%s$reset" \
        "$error_text$text$input_text"

end
