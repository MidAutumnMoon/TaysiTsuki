#!/usr/bin/env ruby

# frozen_string_literal: true

require "English"

PNAME = "mimic-cloud-init"
BINNAME = PNAME
SERVER = "uk-01"

system <<~SH or abort "Failed to copy drv onto server"
    nix copy --to ssh-ng://#{SERVER} ".#tsuki.#{PNAME}" \
        --no-check-sigs
SH

path = `nix eval --raw .#tsuki.#{PNAME}`.chomp
abort "Failed to eval drv" unless $CHILD_STATUS.success?

system <<~SH or abort "Failed to run drv"
    ssh #{SERVER} "#{path}/bin/#{BINNAME}"
SH
