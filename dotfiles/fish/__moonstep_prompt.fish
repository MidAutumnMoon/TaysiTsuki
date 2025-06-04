set -g __prompt_text_ok '$'
set -g __prompt_text_err '$'
set -g __prompt_input_text '>'

set -g __prompt_ok_color ( set_color blue )
set -g __prompt_err_color ( set_color red )

function __moonstep_prompt

    if [ "$__moonstep_saved_status" = 0 ]
        set -f text "$__prompt_text_ok"
        set -f color "$__prompt_ok_color"
    else
        set -f text "$__prompt_text_err"
        set -f color "$__prompt_err_color"
        set -f error_text "($__moonstep_saved_status)"
    end

    __moonstep_printf \
        "$color%s$__color_reset" \
        "$text$error_text$__prompt_input_text"

end
