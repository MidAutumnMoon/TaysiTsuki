# 1)
#
# Grab the status of Bash and launch fish in
# login or interactive mode accordingly.

declare fish_params

if shopt -q login_shell; then
    fish_params="--login"
elif [[ $- == *i* ]]; then
    fish_params="--interactive"
fi

# 2)
#
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

# 3)
#
# Launch fish (or not)

if [[ "$parents_have_fish" = "false" ]]; then
    exec fish "$fish_params"
fi
