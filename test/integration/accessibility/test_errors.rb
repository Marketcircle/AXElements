# -*- coding: utf-8 -*-
require 'test/integration/helper'

class TestAccessibilityErrors < MiniTest::Unit::TestCase

  def test_search_failure_shows_arguments
    e = Accessibility::SearchFailure.new(app, :list, {herp: :derp}) { }
    def e.backtrace; []; end
    assert_match /Could not find `List\(herp: :derp\)\[✔\]`/, e.message

    e = Accessibility::SearchFailure.new(app, :list, {herp: :derp})
    def e.backtrace; []; end
    assert_match /Could not find `List\(herp: :derp\)`/, e.message
    assert_match /as a child of AX::Application/, e.message
    assert_match /Element Path:\n\t\#<AX::Application/, e.message

    e = Accessibility::SearchFailure.new(app, :list, {})
    def e.backtrace; []; end
    assert_match /Could not find `List`/, e.message

    e = Accessibility::SearchFailure.new(app, :list, nil)
    def e.backtrace; []; end
    assert_match /Could not find `List`/, e.message
  end

  def test_search_failure_shows_element_path
    e = Accessibility::SearchFailure.new(app.menu_bar, :trash_dock_item, nil)
    def e.backtrace; []; end
    assert_match /AX::Application/, e.message
    assert_match /AX::MenuBar/, e.message
  end

  def test_search_failure_includes_subtree_in_debug_mode
    assert Accessibility.debug?, 'Someone turned debugging off'
    e = Accessibility::SearchFailure.new(app.menu_bar, :trash_dock_item, nil)
    def e.backtrace; []; end
    assert_match /Subtree:/, e.message
    assert_match app.menu_bar.inspect_subtree, e.message
  end

end
