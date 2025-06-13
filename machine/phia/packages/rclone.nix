{
    lib,
    writeShellApplication,
    rclone,
}:

writeShellApplication {
    name = ",rclone";
    text = ''
        # Bug in cgo resolver?
        # It doesn't work with mDNS
        export GODEBUG=netdns=go
        command "${lib.getExe rclone}" \
            --config "/etc/rclone.conf" \
            --progress \
            --human-readable \
            --multi-thread-cutoff "128M" \
            --multi-thread-streams "4" \
            "$@"
    '';
}
