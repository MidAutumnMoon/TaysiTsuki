{
    lib,
    writeShellApplication,
    rclone,
}:

writeShellApplication {
    name = ",rclone";
    text = ''
        command "${lib.getExe rclone}" \
            --config "/etc/rclone.conf" \
            --progress \
            --human-readable \
            --multi-thread-cutoff "128M" \
            --multi-thread-streams "4" \
            "$@"
    '';
}
