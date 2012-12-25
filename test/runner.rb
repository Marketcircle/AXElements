$LOAD_PATH << 'lib'

require 'rubygems'
require 'minitest/autorun'

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
  require 'accessibility/extras'
  NSWorkspace.sharedWorkspace.runningApplications.find do |app|
    app.bundleIdentifier == name
  end.processIdentifier
end
