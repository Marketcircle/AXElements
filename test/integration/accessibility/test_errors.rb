require 'test/integration/helper'

class TestAccessibilityErrors < MiniTest::Unit::TestCase

  def except klass, *args
    e = klass.new(*args)
    def e.backtrace; [] end
    e
  end

  def l; AX::DOCK.children.first end

  def test_search_failure_shows_arguments
    e = except Accessibility::SearchFailure, AX::DOCK, :list, {herp: :derp}
    assert_match /Could not find `List\(herp: :derp\)`/, e.message
    assert_match /as a child of AX::Application/, e.message
    assert_match /Element Path:\n\t\#<AX::Application/, e.message

    e = except Accessibility::SearchFailure, AX::DOCK, :list, {}
    assert_match /Could not find `List`/, e.message

    e = except Accessibility::SearchFailure, AX::DOCK, :list, nil
    assert_match /Could not find `List`/, e.message
  end

  def test_search_failure_shows_element_path
    e = except Accessibility::SearchFailure, l, :trash_dock_item, nil
    assert_match /AX::Application/, e.message
    assert_match /AX::List/, e.message
  end

  def test_search_failure_includes_subtree_in_debug_mode
    assert Accessibility::Debug.on?, 'Someone turned debugging off'
    e = except Accessibility::SearchFailure, l, :trash_dock_item, nil
    assert_match /Subtree:/, e.message
    assert_match subtree_for(l), e.message
  end

  def test_polling_timeout_modifies_message
    e = except Accessibility::PollingTimeout, l, :trash_dock_item, nil
    assert_match /^Timed out waiting/, e.message
  end

end
