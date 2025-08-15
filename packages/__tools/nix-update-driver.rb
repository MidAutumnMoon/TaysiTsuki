#!/usr/bin/env ruby

# frozen_string_literal: true

# ./nix-update-driver.rb MANIFEST REPORT
#
# MANIFEST: path of a .rb file contains array of packages that needs to be updated
# REPORT: path of file for writing update reports to

require "English"
require "reinbow"
require "stringio"
require "tempfile"
require "shellwords"

require "async"
require "async/barrier"
require "async/semaphore"

using Reinbow

#
# Setup
#

abort "nix-update not found" \
    unless system( "nix-update --help", out: File::NULL )

abort "wrong number of options, expecting 2" \
    unless ARGV.size == 2

MANIFEST = File.read( ARGV.shift )
REPORT = File.new( ARGV.shift, File::RDWR | File::TRUNC | File::CREAT )

# Switch the pwd to the toplevel of git repo, which also contains flake.nix
# in this case. Otherwise nix-update will complain about unable to find flake.nix.
lambda do
    toplevel = `git rev-parse --show-toplevel`
    abort "Failed to get toplevel using git" \
        unless $CHILD_STATUS.success? && !toplevel.empty?
    warn "Change pwd to #{toplevel}".yellow
    Dir.chdir toplevel.strip
end.call

#
# Attributes of packages to be updated
#

# rubocop:disable Security/Eval
PACKAGES = eval MANIFEST, TOPLEVEL_BINDING
# rubocop:enable Security/Eval

#
# Run nix-update
#

REPORT.puts <<~MARKDOWN
    ## nix-update reports
MARKDOWN


Sync do

    barrier = Async::Barrier.new
    semaphore = Async::Semaphore.new( 6, parent: barrier )

    tasks = []

    PACKAGES.each do |package|
        warn "Run nix-update on #{package}".yellow

        attribute = nil
        extra_opts = []

        case package
        in String
            attribute = package
        in { pinned: true }
            warn "Package #{package} is being pinned".yellow
            next
        in { attr:, unstable: true }
            attribute = attr
            extra_opts << %(--version=branch)
        in { attr:, regex: }
            attribute = attr
            extra_opts << %(--version-regex="#{regex}")
        in { attr:, preview: true }
            attribute = attr
            extra_opts << %(--version=unstable)
        else
            abort "Unknown manifest format"
        end

        tasks << semaphore.async do
            logfile = Tempfile.create

            system <<~CMD or abort "Failed to run nix-update"
                nix-update \
                    #{extra_opts.join( ' ' )} \
                    --write-commit-message "#{logfile.path}" \
                    --flake "#{attribute}"
            CMD

            # This first of commit message from nix-update is package's name
            # with version bumps after it. This adds a Markdown heading before it.
            log_content = logfile.read
            REPORT.puts "### #{log_content}" if not log_content.empty?
        ensure
            logfile.close
        end
    end

    tasks.map( &:wait )

ensure

    barrier.stop

end
