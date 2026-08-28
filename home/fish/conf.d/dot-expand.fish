# Expand "..." to "../.." and so on, copied from puffer-fish
function __expand_dot
    if commandline --search-field >/dev/null
        commandline --search-field --insert '.'
    else if string match --quiet --regex -- '^(\.\./)*\.\.$' "$(commandline --current-token)"
        commandline --insert '/..'
    else
        commandline --insert '.'
    end
end

status is-interactive; and bind '.' __expand_dot
