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
        @manifest = Pathname.new( path )
            .then { Manifest.load it }
    end

    def self.load( manifest_path )
        # 1. Ensure it's a file
        raise ArgumentError, %("#{manifest_path}" is not a file) \
            unless manifest_path.file?

        # 2. Eval the file for manifest content
        # rubocop:disable Security/Eval
        manifest = eval( manifest_path.read )
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
    "--option narinfo-cache-negative-ttl 0",
    "--option keep-going true",
    "--option max-jobs 1",
].join( " " )

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
    cachix = ARGV.shift

    # turn [ "a", "b" ] into ".#a .#b" for nix cli
    nix_option = manifest.get( subject )
        .map { ".##{it}" }
        .join " "

    system <<~SH or abort "Failed to build"
        nix build #{nix_option} #{COMMON_NIX_CLI_OPTS}
    SH

in "nixos"
    warn "Command: nixos".blue

    eval_driver = <<~NIX
        toString #{Dir.pwd}
        |> builtins.getFlake
        |> ( it: it.nixosConfigurations )
        |> builtins.attrNames
    NIX

    eval_driver = eval_driver.then do |text|
        temp = Tempfile.create
        temp.write text
        temp.flush
        temp
    end

    build_opts = `nix eval -f #{eval_driver.to_path} --json`
        .then { JSON.parse it }
        .map { ".#nixosConfigurations.#{it}.config.system.build.toplevel" }
        .join( " " )

    system <<~SH or abort "Failed to build"
        nix build #{build_opts} #{COMMON_NIX_CLI_OPTS}
    SH

else
    abort "Unreachable"
end
