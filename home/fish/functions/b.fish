function b
    set --erase RUST_LOG RUST_BACKTRACE
    set -f upwards (command derputils upwards)
    or return

    cd "$upwards"
end
