function __moonstep_printf --no-scope-shadowing
    printf $argv | string trim --chars "\n "
end
