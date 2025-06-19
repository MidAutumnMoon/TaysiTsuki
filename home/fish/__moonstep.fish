#
# Async prompt implementation.
# Modified from
# https://github.com/acomagu/fish-async-prompt
#

status is-interactive || exit 0

set -g __moonstep_result_prefix \
    __moonstep_rendered_prompt_{$fish_pid}_

set -g __moonstep_notifier \
    __moonstep_finish_notifier_{$fish_pid}

set -g __moonstep_prompt_fns \
    fish_prompt \
    fish_right_prompt

# Hijack the prompt function to only print the result
# from the result pipeline.
#
# 1) The hijack only happends in current shell
# 2) The prompt functions are executed in new fish process
# 3) This script won't be sourced in child fish, because of
#    the `status is-interactive` check
# 4) And because this script is not sourced, the child fish will
#    run the original prompt functions to render prompts
#
# This is the essential of this async prompt implementation.
#
# The hijacked function will print last rendered prompt,
# instead the updating and drawing of new prompt is handled by
# __moonstep_repaint function, triggered when child process finishes.
function __moonstep_setup --on-event fish_prompt
    functions --erase ( status function )
    for fn in $__moonstep_prompt_fns
        eval "
            function $fn
                printf \$$__moonstep_result_prefix$fn
            end
        "
    end
end

function __moonstep_fire --on-event fish_prompt
    __moonstep_save_variables
    for fn in $__moonstep_prompt_fns
        __moonstep_spawn "$fn"
    end
end

function __moonstep_spawn -a fn
    set -f serialize_envvar

    for var in ( __moonstep_inherited_variables )
        set --append serialize_envvar \
            "$var $( string escape -- $$var )"
    end

    set -f runner "
        # deserialize envvars
        while read -a vardata
            test -z \"\$vardata\" && continue
            eval set -g \$vardata
        end

        '$fn' | read --null -l rendered

        # send off the rendered prompt
        set -U '$__moonstep_result_prefix$fn' \"\$rendered\"

        # notify that we're finished
        set -U '$__moonstep_notifier' 1
    "

    # N.B. add newline after each item otherwise `read` in `runner`
    # will read everything into one line
    printf "%s\n" $serialize_envvar \
        | env ( status fish-path ) -c "$runner" 1>/dev/null &

    disown
end

function __moonstep_repaint \
    --on-variable "$__moonstep_notifier"
    block -l
    set --erase -U "$__moonstep_notifier"
    commandline -f repaint
end

# The original `fish-async-prompt` emulates $status and other
# readonly variables by running functions that returns
# that status in child process.
# It is more straghitforward by capturing variables
# ourselves, but it's also more messier to use.
function __moonstep_save_variables
    set -g __moonstep_saved_status $status
    set -g __moonstep_saved_cmd_duration $CMD_DURATION
    set -g __moonstep_saved_pipestatus $pipestatus
end

function __moonstep_inherited_variables
    set -gn | string match "__moonstep_saved*"
end

# Delete universal variables. They are stateful and persistant.
function __moonstep_clean --on-event fish_exit
    block -l
    for var in ( set -Un \
        | string match "$__moonstep_result_prefix*" )
        set -U --erase $var
    end
    set -U --erase "$__moonstep_notifier"
end
