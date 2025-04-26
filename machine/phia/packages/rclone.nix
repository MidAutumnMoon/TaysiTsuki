{
    writeShellApplication,
    rclone,
}:

writeShellApplication {
    name = ",rclone";
    runtimeInputs = [ rclone ];

    text = ''
        command rclone \
            --config "/etc/rclone.conf" \
            --progress \
            --human-readable \
            --multi-thread-cutoff "128M" \
            --multi-thread-streams "4" \
            --exclude "/.recycle/" \
            "$@"
    '';
}
