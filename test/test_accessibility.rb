class TestAccessibility < TestAX

  APP = AX::Application.new APP_REF

end


class TestAccessibilityPath < TestAccessibility

  def setup
    @list = Accessibility.path(APP.main_window.close_button)
  end

  def test_returns_array_of_elements
    assert_instance_of Array, @list
    assert_kind_of     AX::Element, @list.first
  end

  def test_correctness
    assert_equal 3, @list.size
    assert_instance_of AX::CloseButton,    @list.first
    assert_instance_of AX::StandardWindow, @list.second
    assert_instance_of AX::Application,    @list.third
  end

end


class TestAccessibilityTree < TestAccessibility

  def test_gives_me_a_tree
    assert_instance_of Accessibility::Tree, Accessibility.tree(APP)
    assert_instance_of Accessibility::Tree, Accessibility.tree(APP)
    assert_instance_of Accessibility::Tree, Accessibility.tree(APP)
    assert_instance_of Accessibility::Tree, Accessibility.tree(APP)
  end

end


class TestAccessibilityElementUnderMouse < MiniTest::Unit::TestCase

  def test_returns_some_kind_of_ax_element
    assert_kind_of AX::Element, Accessibility.element_under_mouse
  end

  # @todo move the mouse to a known location, and then ask for the element

end


class TestAccessibilityElementAtPoint < MiniTest::Unit::TestCase
end


class TestAccessibilityApplicationWithBundleIdentifier < MiniTest::Unit::TestCase

  def test_makes_an_app
    ret = Accessibility.application_with_bundle_identifier(APP_BUNDLE_IDENTIFIER)
    assert_instance_of AX::Application, ret
  end

  def test_gets_app_when_app_is_already_running
    app = Accessibility.application_with_bundle_identifier 'com.apple.dock'
    assert_instance_of AX::Application, app
    assert_equal 'Dock', app.attribute(:title)
  end

  # how do we test when app is not already running?

  def test_launches_app_if_it_is_not_running
    skip 'Another difficult test to implement'
  end

  def test_times_out_if_app_cannot_be_launched
    skip 'This is difficult to do...'
  end

  def test_allows_override_of_the_sleep_time
    skip 'This is difficult to test...'
  end

end


class TestAccessibilityApplicationWithName < MiniTest::Unit::TestCase

  def test_application_with_name_with_proper_app
    ret = Accessibility.application_with_name 'Dock'
    assert_instance_of AX::Application, ret
    assert_equal       'Dock', ret.title
  end

  def test_application_with_name_with_non_existant_app
    assert_nil Accessibility.application_with_name('App That Does Not Exist')
  end

end


class TestAccessibilityApplicationWithPID < MiniTest::Unit::TestCase
end
