function __zellij_update_tab_name --on-variable PWD
    set --query ZELLIJ
    or return

    set -f dir (string split "/" $PWD)[-1]
    command zellij action rename-tab "<$dir>"
end

# run once at startup
__zellij_update_tab_name
