# frozen_string_literal: true

require "pathname"
require "English"

def repo_toplevel
    path = `git rev-parse --show-toplevel`
    abort "Failed to run git rev-parse" unless $CHILD_STATUS.success?
    Pathname.new( path.strip )
end
