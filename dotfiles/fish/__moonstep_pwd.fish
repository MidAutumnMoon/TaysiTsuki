function __moonstep_pwd
    pwd | string replace --regex "^$HOME" "~"
end
