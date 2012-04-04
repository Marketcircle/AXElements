require 'test/integration/helper'
require 'rspec/expectations/ax_elements'

class TestRSpecMatchers < MiniTest::Unit::TestCase

  def app
    @@app ||= AX::Application.new PID
  end

  def test_have_child_should_failure_message
    m = Accessibility::HasChildMatcher.new(:window, {}) {}
    e = app.main_window.slider

    m.matches? e
    assert_equal "Expected #{e.inspect} to have child Window[✔]",
      m.failure_message_for_should
  end

  def test_have_child_should_not_failure_message
    m = Accessibility::HasChildMatcher.new(:window, {})
    e = app.window

    m.does_not_match? app
    assert_equal "Expected #{app.inspect} to NOT have child #{e.inspect}",
      m.failure_message_for_should_not
  end

  def test_have_child_description
    m = Accessibility::HasChildMatcher.new(:window,{}) {}
    assert_equal 'should have a child that matches Window[✔]', m.description
  end

  def test_have_descendent_should_failure_message
    m = Accessibility::HasDescendentMatcher.new(:button, {}) {}
    q = Accessibility::Qualifier.new(:Button,{}) {}
    e = app.main_window.slider

    m.matches? e
    assert_equal "Expected #{e.inspect} to have descendent Button[✔]",
      m.failure_message_for_should
  end

  def test_have_descendent_should_not_failure_message
    m = Accessibility::HasDescendentMatcher.new(:window,{})
    e = app.window

    m.does_not_match? app
    assert_equal "Expected #{app.inspect} to NOT have descendent #{e.inspect}",
      m.failure_message_for_should_not
  end

  def test_have_descendent_description
    m = Accessibility::HasDescendentMatcher.new(:button,{})
    assert_equal 'should have a descendent matching Button', m.description
  end

end


begin
  raise LoadError
  require 'rspec-core'
  RSpec::Core::Runner.disable_autorun!
  RSpec.configuration.mock_with :nothing

  class TestRSpecMatchers

    def test_have_child
      describe Accessibility::HasChildMatcher do
        it "should find"
        it "shoud fail to find"
        it "should not find"
        it "should fail to not find"
      end
      RSpec.world.example_groups.map { |x| x.run }
    end

    def test_have_descendent
      describe Accessibility::HasDescendentMatcher do
        it "should find"
        it "shoud fail to find"
        it "should not find"
        it "should fail to not find"
      end
      RSpec.world.example_groups.map { |x| x.run }
    end

  end

rescue LoadError
  $stderr.puts 'You do not have rspec installed, skipping RSpec integration tests'
end
