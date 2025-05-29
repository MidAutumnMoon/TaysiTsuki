#!/usr/bin/env ruby

# frozen_string_literal: true

# ./script SUBCOMMAND
#
# SUBCOMMAND can be one of:
#   - "subjects"
#   - "build"
#   - "nixos"
#
# SUBCOMMAND options
#
#   "subjects" MANIFEST : Get the subjects to build
#   - MANIFEST: The manifest.rb file
#
#   "build" MANIFEST SUBJECT : Build some subject
#   - MANIFEST: The manifest.rb file
#   - SUBJECT: Something listed in MANIFEST to build
#
#   "nixos" : Build NixOS

require "reinbow"
require "pathname"
require "json"
require "English"
require "tempfile"

using Reinbow

SUBCOMMAND = begin
    cmd = ARGV.shift
    abort %(Wrong subcommand "#{cmd}") \
        unless cmd in "subjects" | "build" | "nixos"
    cmd
end

class Manifest
    @manifest = nil

    def initialize( path )
        @manifest = Manifest.load path
    end

    def self.load( manifest_path )
        manifest_path = Pathname.new manifest_path

        # 1. Ensure it's a file
        raise ArgumentError, %("#{manifest_path}" is not a file) \
            unless manifest_path.file?

        # 2. Eval the file for manifest content
        # rubocop:disable Security/Eval
        manifest = eval( manifest_path.read, TOPLEVEL_BINDING )
        # rubocop:enable Security/Eval
        raise ArgumentError, %(Manifest does not contain a hash) \
            if not manifest.is_a? Hash

        # 3. Ensure each subject is the right shape
        #
        # Currently subjects are required to be a list of strings,
        # but it may get extened in the future.
        manifest.each_value do |value|
            ( value in Array and value.all? { it in String } ) \
            or raise ArgumentError, %(Unexpected subject shape "#{value}")
        end

        @manifest = manifest
    end

    def keys = @manifest.keys
    def get( sub ) = @manifest[sub.to_sym]
end

COMMON_NIX_CLI_OPTS = [
    "--print-build-logs",
    "--keep-failed",
    "--option narinfo-cache-negative-ttl 0",
    "--option keep-going true",
    "--option max-jobs 4",
].join( " " )

def move_builddir_on_disk
    nixdir = Pathname.new "/nix"
    builddir = nixdir.join "nixbuild"
    builddir.mkdir
        .then { abort "Failed to mkdir" if it != 0 }
    ENV["TMPDIR"] = builddir.to_s
end

case SUBCOMMAND

in "subjects"
    warn "Command: subjects".blue
    abort "Wrong number of options, expecting 1" \
        unless ARGV.size == 1
    manifest = Manifest.new( ARGV.shift )
    puts manifest.keys.to_json

in "build"
    warn "Command: build".blue
    abort "Wrong number of options, expecting 2" \
        unless ARGV.size == 2

    manifest = Manifest.new( ARGV.shift )
    subject = ARGV.shift

    # turn [ "a", "b" ] into ".#a .#b" for nix cli
    nix_option = manifest.get( subject )
        .map { ".##{it}" }
        .join " "

    move_builddir_on_disk

    system <<~SH or abort "Failed to build"
        nix build #{nix_option} #{COMMON_NIX_CLI_OPTS}
    SH

in "nixos"
    warn "Command: nixos".blue

    eval_hostnames = <<~NIX
        toString #{Dir.pwd}
        |> builtins.getFlake
        |> ( it: it.nixosConfigurations )
        |> builtins.attrNames
    NIX

    eval_hostnames = begin
        temp = Tempfile.create
        temp.write eval_hostnames
        temp.flush
        temp.to_path
    end

    build_opts = `nix eval -f #{eval_hostnames} --json`
        .then { JSON.parse it }
        .map { ".#nixosConfigurations.#{it}.config.system.build.toplevel" }
        .join( " " )

    move_builddir_on_disk

    system <<~SH or abort "Failed to build"
        nix build #{build_opts} \
            --option max-jobs 16 \
            #{COMMON_NIX_CLI_OPTS}
    SH

else
    abort "Unreachable"
end
