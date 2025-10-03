#!/usr/bin/env ruby

# frozen_string_literal: true

require "English"
require "tmpdir"
require "pathname"

abort "bundix not found" \
    unless system "bundix --version", out: File::NULL


HERE = Pathname.new __dir__

GEMFILE = <<~GEM
    source "https://rubygems.org"
    gem "amazing_print"
    gem "reinbow"
    gem "irb"
GEM

GEMFILE_RUBOCOP = <<~GEM
    source "https://rubygems.org"
    gem "rubocop"
GEM

# Maps the content of Gemfile to the filename
# of output gemset.nix
MAPPING = {
    GEMFILE => "gemset.nix",
    GEMFILE_RUBOCOP => "gemset-rubocop.nix",
}.freeze


class Pathname
    alias to_str to_path
end


MAPPING.each_pair do |gemfile_content, gemset_name|

    tmpdir = Pathname.new( Dir.mktmpdir )

    ENV["HOME"] = tmpdir
    ENV["BUNDLE_USER_HOME"] = tmpdir
    ENV["XDG_CACHE_HOME"] = tmpdir

    gemfile = tmpdir / "Gemfile"
    gemfile.write gemfile_content

    gemlock = tmpdir / "Gemfile.lock"

    generated_gemset = HERE / gemset_name

    Dir.chdir tmpdir do
        system "bundle lock --verbose --lockfile=#{gemlock}"
        abort "Failed to run bundle lock" \
            unless $CHILD_STATUS.success?
    end

    system <<~RUN
        bundix \
            --gemfile "#{gemfile}" \
            --lockfile "#{gemlock}" \
            --gemset "#{generated_gemset}"
    RUN

    abort "Failed to run bundix" \
        unless $CHILD_STATUS.success?

end
