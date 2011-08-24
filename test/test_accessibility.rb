class TestAccessibility < TestAX

  APP = AX::Application.new REF

  def close_button
    @@button ||= APP.attribute(:main_window).attribute(:children).find do |item|
      item.class == AX::CloseButton
    end
  end

  def test_path_returns_correct_elements_in_correct_order
    list = Accessibility.path(APP.main_window.close_button)
    assert_equal 3, list.size
    assert_instance_of AX::CloseButton,    list.first
    assert_instance_of AX::StandardWindow, list.second
    assert_instance_of AX::Application,    list.third
  end

  def test_graph
    skip 'ZOMG, yeah right'
  end

  def test_dump_works_for_nested_tab_groups
    element = APP.main_window.children.find { |item| item.role == KAXTabGroupRole }
    output  = Accessibility.dump(element)

    refute_empty output

    expected = [
                ['AX::TabGroup',    0],
                ['AX::RadioButton', 1], ['AX::RadioButton', 1], ['AX::TabGroup', 1],
                ['AX::RadioButton', 2], ['AX::RadioButton', 2], ['AX::TabGroup', 2],
                ['AX::RadioButton', 3], ['AX::RadioButton', 3], ['AX::TabGroup', 3],
                ['AX::RadioButton', 4], ['AX::RadioButton', 4],
                ['AX::Group', 4],
                ['AX::TextField',   5], ['AX::StaticText',  6],
                ['AX::TextField' ,  5], ['AX::StaticText',  6]
               ]

    output = output.split("\n")

    until output.empty?
      actual_line             = output.shift
      expected_klass, indents = expected.shift
      assert_equal indents, actual_line.match(/^\t*/).to_a.first.length, actual_line
      actual_line.strip!
      assert_match /^\#<#{expected_klass}/, actual_line
    end
  end

  def test_returns_some_kind_of_ax_element
    assert_kind_of AX::Element, Accessibility.element_under_mouse
  end

  def test_returns_element_under_the_mouse
    button = APP.main_window.close_button
    Mouse.move_to button.position, 0.0
    assert_equal button, Accessibility.element_under_mouse
  end

  def test_element_at_point_returns_button_when_given_buttons_coordinates
    point = close_button.position
    assert_equal close_button, Accessibility.element_at_point(*point.to_a)
    assert_equal close_button, Accessibility.element_at_point(point.to_a)
    assert_equal close_button, Accessibility.element_at_point(point)
  end

  def test_elemnent_at_point_is_element_at_position
    assert_equal Accessibility.method(:element_at_point), Accessibility.method(:element_at_position)
  end

  def test_application_with_name_gets_app_if_running
    ret = Accessibility.application_with_name 'Dock'
    assert_instance_of AX::Application, ret
    assert_equal       'Dock', ret.title
  end

  def test_application_with_name_gets_nil_if_not_found
    assert_nil Accessibility.application_with_name('App That Does Not Exist')
  end

  def test_application_with_name_called_before_and_after_app_is_running
    skip 'This is a bug that was fixed but should have a test'
  end

  def test_app_with_bundle_id_returns_the_correct_app
    ret = Accessibility.application_with_bundle_identifier(APP_BUNDLE_IDENTIFIER)
    assert_instance_of AX::Application, ret
    assert_equal APP, ret
  end

  def test_app_with_bundle_id_return_app_if_app_is_running
    app = Accessibility.application_with_bundle_identifier 'com.apple.dock'
    assert_equal 'Dock', app.attribute(:title)
  end

  # @todo how do we test when app is not already running?

  def test_launches_app_if_it_is_not_running
    def grabbers
      NSRunningApplication.runningApplicationsWithBundleIdentifier( 'com.apple.Grab' )
    end
    grabbers.each do |dude| dude.terminate end
    assert_empty grabbers
    Accessibility.application_with_bundle_identifier( 'com.apple.Grab' )
    refute_empty grabbers
  ensure
    grabbers.each do |dude| dude.terminate end
  end

  def test_app_with_bundle_id_times_out_if_app_cannot_be_launched
    skip 'This is difficult to do...'
  end

  def test_app_with_bundle_id_allows_override_of_the_sleep_time
    skip 'This is difficult to test...'
  end

  # @note a bad pid will crash MacRuby
  def test_application_with_pid_gives_me_the_application
    pid = APP.pid
    app = Accessibility.application_with_pid(pid)
    assert_equal APP, app
  end

end
