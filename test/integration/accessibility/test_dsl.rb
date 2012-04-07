# -*- coding: utf-8 -*-
require 'test/integration/helper'

class TestAccessibilityDSL < MiniTest::Unit::TestCase

  # LSP FTW
  class DSL
    include Accessibility::DSL
  end

  def dsl
    @dsl ||= DSL.new
  end

  def app;             @@app       ||= AX::Application.new REF                               end
  def text_area;       @@text_area ||= app.main_window.text_area                             end
  def pref_window;     app.children.find { |x| x.attribute(:title) == 'Preferences'   }      end
  def spelling_window; app.children.find { |x| x.attribute(:title).to_s.match(/^Spelling/) } end

  def try_typing string, expected = nil
    expected = string unless expected
    text_area.set :focused, true
    assert text_area.focused?
    dsl.type string, app
    assert_equal expected, text_area.value
  ensure # reset for next test
    dsl.type "\\COMMAND+a \b", app
  end

  def test_dsl_is_mixed_into_toplevel
    assert_includes Object.new.class.ancestors, Accessibility::DSL
  end

  def test_application_with_bundle_id
    assert_equal app, dsl.app_with_bundle_identifier(APP_BUNDLE_IDENTIFIER)
    assert_equal app, dsl.app_with_bundle_id(APP_BUNDLE_IDENTIFIER)
    assert_equal app, dsl.launch(APP_BUNDLE_IDENTIFIER)
  end

  def test_application_with_name
    assert_equal app, dsl.app_with_name('AXElementsTester')
  end

  def test_application_with_pid
    assert_equal app, dsl.app_with_pid(PID)
  end

  def test_set_focus_to
    assert dsl.set_focus_to app
    assert dsl.set_focus    app
    assert dsl.set_focus_to app.main_window.search_field
    assert dsl.set_focus    app.main_window.search_field
  end

  def test_set
    expected = 'Octocat is not Hello Kitty!'
    field    = app.main_window.search_field
    dsl.set field, expected
    assert_equal expected, field.value
  ensure
    field.set :value, '' if field
  end

  def test_typing_human_string
    try_typing "A sentence, with punctuation and num8ers. LOL!\tA 'quoted' string--then some @#*$."
  end

  def test_typing_backspaces
    try_typing "The cake is a lie!\b\b\b\bgift!", 'The cake is a gift!'
  end

  def test_typing_hotkeys
    try_typing ", world!\\CONTROL+a Hello", 'Hello, world!'
    try_typing "MacRuby\\OPTION+2",         'MacRuby™'
  end

  def test_typing_command_keys
    try_typing "Hai.\\<- \\<- \b", "Hi."
  end

  def test_typing_ruby_escapes
    try_typing "First.\nSecond."
  end

  def test_select_menu_item_string
    assert_nil pref_window
    dsl.select_menu_item app, app.title, 'Preferences…'
    window = dsl.wait_for :window, parent: app, title: 'Preferences'
    refute_nil window
  ensure
    window.close_button.perform :press if window
  end

  def test_select_menu_item_regexp
    assert_nil spelling_window
    dsl.select_menu_item app, /Edit/, /Spelling/, /show spelling/i
    window = dsl.wait_for :floating_window, parent: app
    refute_nil window
  ensure
    window.close_button.perform :press if window
  end

  def test_select_menu_item_raises_if_cannot_find_item
    assert_raises Accessibility::SearchFailure do
      dsl.select_menu_item app, 'File', 'NonExistantMenuItem'
    end
    # @todo verify that menu is closed
  end

  def test_select_menu_item_provides_proper_debug_info
    e = assert_raises Accessibility::SearchFailure do
      dsl.select_menu_item app, 'Format', 'Front'
    end
    assert_match /MenuItem/, e.message
  end

  def test_wait_for_obeys_timeout_option
    # loop sleeps for 0.2, so we have to wait at least that long
    start = Time.now
    dsl.wait_for :strawberry_rhubarb, parent: AX::DOCK, timeout: 0.2
    assert_in_delta Time.now, start, 0.3
  end

  def test_wait_for_parent_only_looks_at_children
    result = dsl.wait_for :trash_dock_item, parent: AX::DOCK, timeout: 0.5
    assert_nil result

    result = dsl.wait_for :trash_dock_item, parent: AX::DOCK.list
    assert_equal AX::DOCK.list.trash_dock_item, result

    result = dsl.wait_for :button, parent: app.main_window, title: 'Yes'
    assert_equal 'Yes', result.title
  end

  def test_wait_for_ancestor_searches
    result = dsl.wait_for :trash_dock_item, ancestor: AX::DOCK
    assert_equal AX::DOCK.list.trash_dock_item, result

    result = dsl.wait_for :nothing, ancestor: AX::DOCK, timeout: 0.5
    assert_nil result

    result = dsl.wait_for :text_field, ancestor: app.main_window, value: 'AXIsNyan'
    assert_equal 'AXIsNyan', result.value
  end

  def test_system_wide
    assert_instance_of AX::SystemWide, dsl.system_wide
  end

  def test_element_under_mouse
    [
      app.main_window.close_button,
      app.main_window.value_indicator
    ].each do |element|
      dsl.move_mouse_to element
      assert_equal element, dsl.element_under_mouse
    end
  end

  def test_element_at_point_for_app
    [
      app.main_window.minimize_button,
      app.main_window.increment_arrow
    ].each do |element|
      assert_equal element, dsl.element_at_point(element, for: app)
    end
  end

  # @todo We aren't being very thorough here
  def test_element_at_point
    [
      app.main_window.minimize_button,
      app.main_window.increment_arrow
    ].each do |element|
      assert_equal element, dsl.element_at_point(element)
    end
  end

  def test_show_about_window
    dialog = dsl.show_about_window_for app
    assert_instance_of AX::Dialog, dialog
    assert_equal 'AXElementsTester icon', dialog.image.description
  ensure
    dialog.close_button.perform :press if dialog
  end

  def test_show_prefs_for_app
    prefs = dsl.show_preferences_window_for app
    assert_kind_of AX::Window, prefs
    assert_equal 'Preferences', prefs.title
  ensure
    prefs.close_button.perform :press if prefs
  end

  def test_scroll_to
    table = app.main_window.table
    ['AXIsNyan', 'AXSubrole'].each do |attr|
      text = table.text_field(value: attr)
      dsl.scroll_to text
      assert NSContainsRect(table.bounds, text.bounds)
    end
  end

  def test_scroll_menu_to
    pop_up = app.main_window.pop_up_button

    pop_up.perform :press
    item = wait_for :menu_item, ancestor: pop_up, title: '49'
    dsl.scroll_menu_to item
    assert_equal item, element_under_mouse
    dsl.click
    assert_equal '49', pop_up.value

    pop_up.perform :press
    item = wait_for :menu_item, ancestor: pop_up, title: 'Togusa'
    dsl.scroll_menu_to item
    assert_equal item, element_under_mouse
    dsl.click
    assert_equal 'Togusa', pop_up.value

  ensure
    unless pop_up.children.empty?
      pop_up.menu_item.perform :cancel
    end if pop_up
  end

end
