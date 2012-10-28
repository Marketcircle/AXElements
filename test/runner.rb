$LOAD_PATH << 'lib'
require 'accessibility/statistics'

require 'rubygems'
gem     'minitest'
require 'minitest/autorun'

# Laaaaaaaaaaaaaaaaaaaaaame
if RUBY_ENGINE == 'macruby' && `sw_vers -productVersion`.to_f > 10.7
  framework '/System/Library/Frameworks/CoreGraphics.framework'
end

# preprocessor powers, assemble!
if ENV['BENCH']
  require 'minitest/benchmark'
else
  require'minitest/pride'
end


class MiniTest::Unit::TestCase

  def self.bench_range
    bench_exp 100, 100_000
  end

end


# Figure out if we are testing a compiled version of AXElements, since some
# tests will fail due to incomplete MacRuby features.
RUNNING_COMPILED =
  $LOADED_FEATURES.find { |file| file.match /ax_elements.rbo/ }

def pid_for name # sneaky naming
  NSWorkspace.sharedWorkspace.runningApplications.find do |app|
    app.bundleIdentifier == name
  end.processIdentifier
end
