require 'test/helper'
require 'ax_elements'

# Force this to be on for testing
Accessibility.debug = true


class MiniTest::Unit::TestCase

  def app
    @@app ||= AX::Application.new PID
  end

end
