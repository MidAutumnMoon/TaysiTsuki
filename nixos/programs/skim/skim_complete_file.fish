function skim_complete_file

    if command -q "git"
        command git rev-parse --show-toplevel 2> /dev/null \
            | read -l ret
        if [ $pipestatus[1] -eq 0 ]
            set -f toplevel "$ret"
        end
    end

    if [ -z "$toplevel" ]
        set -f toplevel ( pwd )
    end

    # Use the token under cursor as the initial skim query
    # It will be replaced later by the result
    commandline --cut-at-cursor --current-token \
        | read -f initQuery

    command fd \
        --base-directory "$toplevel" \
        --type f \
        --hidden \
        --no-follow \
        --relative-path \
        --exclude ".git" \
        2> /dev/null \
    | command sk \
        --tac \
        --exact \
        --query "$initQuery" \
        --print0 \
        --no-multi \
        2> /dev/null \
    | read --null -f selection

    # all should be 0
    if not string match -qr '^[0 ]*$' "$pipestatus"
        commandline -f repaint
        return
    end

    # no selection, no action
    if [ -z "$selection" ]
        commandline -f repaint
        return
    end

    printf "%s" "$toplevel/$selection" | read -f selection

    # Try trim PWD from the path to make it shorter
    if string match -rq "^$PWD" "$selection"
        string replace -r "^$PWD/" "" "$selection" \
            | string escape \
            | read -f selection
    end

    # Replace $HOME in the path with a shorter and nicer looking "~" sign.
    # This also escaps the path, but crucially not the "~" sign.
    # TODO: escape $HOME?
    if string match -rq "^$HOME" "$selection"
        # escape the remaining path
        string replace -r "^$HOME/" "" "$selection" \
            | string escape \
            | read -l bare
        # prepend an unescaped "~"
        printf "~/%s" "$bare" | read -f selection
        # The result might look like ~/"hello world/file.txt"
    end

    commandline --replace --current-token -- "$selection"
    commandline -f repaint

end
