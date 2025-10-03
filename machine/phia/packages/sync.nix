{
    lib,
    tsuki,
    myRclone,
}:

tsuki.writers.writeRubyBin ",sync" {} /*ruby*/ ''
    # frozen_string_literal: true

    require "shellwords"

    DIRECTION = ARGV.shift

    abort %(Expect an sync direction of either "up" or "down") \
        unless DIRECTION in "up" | "down"

    # N.B. Hardcoded paths!
    # Find a better way to store these knobs
    RCLONE_REMOTE = "Box"
    POOL_DIR = "/srv/pool"

    abort %("rclone.conf" is not at expected location) \
        unless File.file? "/etc/rclone.conf"

    abort %("#{POOL_DIR}" not at expected location) \
        unless File.directory? POOL_DIR

    EXCLUDE_PATTERNS =
        %w[
            /.zfs/
            /.recycle/
            /__Income__/
        ]
            .flat_map { [ "--exclude", it ] }
            .freeze

    RCLONE_DIR_ARGS =
        case DIRECTION
        in "up"
            [ POOL_DIR, "#{RCLONE_REMOTE}:" ]
        in "down"
            [ "#{RCLONE_REMOTE}:", POOL_DIR ]
        end

    system <<~SH or abort "Failed to run rclone!"
        "${lib.getExe myRclone}" sync --refresh-times \
            #{EXCLUDE_PATTERNS.shelljoin} \
            #{RCLONE_DIR_ARGS.shelljoin}
    SH
''
