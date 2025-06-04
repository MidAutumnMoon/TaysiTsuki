# Only launchs fish if it's interactive shell
if [[ $- == *i* ]]; then
    # Walk through parent processes up until PID 1
    # to check if any of them is "fish". If such case
    # is encountered, this Bash process is probably
    # launched using nix shell or develop, in this case
    # don't start a new fish shell.

    declare pid_on_hand="$$"
    declare parents_have_fish="false"

    while [[ "$pid_on_hand" -ne 1 ]]; do
        # Get the command name
        cmd=$( ps -p "$pid_on_hand" -o cmd= )

        if [[ "$cmd" == *fish* ]]; then
            parents_have_fish="true"
            break
        fi

        parent_pid=$( ps -p "$pid_on_hand" -o ppid= )
        # Remove whitespaces from the idiot output
        pid_on_hand="${parent_pid//[[:space:]]}"
    done

    if [[ "$parents_have_fish" = "false" ]]; then
        exec fish --interactive
    fi
fi

