# frozen_string_literal: true

require "shellwords"

require "reinbow"
using Reinbow

DIRECTION = ARGV.shift

abort %(Expect an sync direction of either "up" or "down").red \
    unless DIRECTION in "up" | "down"

# N.B. Hardcoded paths!
# Find a better way to store these knobs
RCLONE_REMOTE = "Box"
POOL_DIR = "/srv/pool"

# abort %("rclone.conf" is not at expected location).red \
#     unless File.file? "/etc/rclone.conf"
#
# abort %("#{POOL_DIR}" not at expected location).red \
#     unless File.directory? POOL_DIR

EXCLUDE_PATTERNS =
    %w[
        /.zfs/
        /.recycle/
        /__Income__/
    ]
        .flat_map { [ "--exclude", it ] }
        .freeze

puts EXCLUDE_PATTERNS

RCLONE_DIR_ARGS =
    case DIRECTION
    in "up"
        [ POOL_DIR, "#{RCLONE_REMOTE}:" ]
    in "down"
        [ "#{RCLONE_REMOTE}:", POOL_DIR ]
    end

system <<~SH
    echo sync \
        #{EXCLUDE_PATTERNS.shelljoin} \
        #{RCLONE_DIR_ARGS.shelljoin}
SH
