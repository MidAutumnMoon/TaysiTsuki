# Only launch fish if it's interactive shell
if [[ $- == *i* && -z $BASH_EXECUTION_STRING ]]; then
    # Walk through parent processes up to PID 1 to check if any is "fish".
    # If found, this Bash was probably launched via nix shell/develop,
    # so don't start a new fish shell (avoid nesting).

    pid=$$
    while [[ "$pid" -ne 1 ]]; do
        # Read directly from /proc - no process forks, much faster than ps
        read -r cmd < "/proc/$pid/comm"
        [[ "$cmd" == "fish" ]] && return

        # Extract PPid from status file
        while read -r key value; do
            [[ "$key" == "PPid:" ]] && { pid=$value; break; }
        done < "/proc/$pid/status"
    done

    SHLVL=$((SHLVL - 1)) exec fish --interactive
fi
