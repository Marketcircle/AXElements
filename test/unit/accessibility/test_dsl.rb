class TestAccessibilityDSL < MiniTest::Unit::TestCase
  include Accessibility::Core

  # LSP FTW
  class DSL
    include Accessibility::DSL
  end

  class LanguageTest < AX::Element
    attr_reader :called_action
    def actions=  value; @actions       = value;  end
    def perform  action; @called_action = action; end
    def search    *args; @search_args   = args;   end
  end

  def dsl
    @dsl ||= DSL.new
  end

  def element
    @element ||= LanguageTest.new REF, attrs_for(REF)
  end

  def test_static_actions
    def static_action action
      dsl.send action, element
      assert_equal action, element.called_action
    end

    static_action :press
    static_action :show_menu
    static_action :pick
    static_action :decrement
    static_action :confirm
    static_action :increment
    static_action :delete
    static_action :cancel
    static_action :hide
    static_action :unhide
    static_action :terminate
    static_action :raise
  end

  def test_method_missing_forwards
    element.actions = ['AXPurpleRain']
    dsl.purple_rain element
    assert_equal :purple_rain, element.called_action

    assert_raises NoMethodError do
      dsl.hack element
    end
    assert_raises NoMethodError do
      dsl.purple_rain 'A string'
    end
  end

  def test_raise_can_still_raise_exception
    assert_raises ArgumentError do
      dsl.raise ArgumentError
    end
    assert_raises NoMethodError do
      dsl.raise NoMethodError
    end
  end

  def test_wait_for_searches_properly
    klass, filters = :cake, {}
    assert_equal [klass, filters], dsl.wait_for(klass,           parent: element)
    assert_equal [klass, filters], dsl.wait_for(klass, as_descendant_of: element)

    klass, filters = :pie, { type: 'Strawberry-Rhubarb' }
    assert_equal [klass, filters], dsl.wait_for(klass, parent: element, filters: filters)
  end

  def test_wait_for_times_out
    herp = Object.new
    def herp.search *args; []; end
    assert_nil dsl.wait_for(:derp, parent: herp, timeout: 0.1)
  end

end
