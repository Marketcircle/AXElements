# -*- coding: utf-8 -*-

require 'test/helper'
require 'accessibility/element'


class TestAccessibilityElement < MiniTest::Unit::TestCase

  def child name
    window.children.find { |item|
      (block_given? ? yield(item) : true) if item.role == name
    }
  end

  def app;         @@app         ||= Accessibility::Element.new REF           end
  def window;      @@window      ||= app.attribute(KAXWindowsAttribute).first end
  def slider;      @@slider      ||= child KAXSliderRole                      end
  def check_box;   @@check_box   ||= child KAXCheckBoxRole                    end
  def pop_up;      @@pop_up      ||= child KAXPopUpButtonRole                 end
  def search_box;  @@search_box  ||= child KAXTextFieldRole                   end
  def static_text; @@static_text ||= child(KAXStaticTextRole) { |x| x.value.match /My Little Pony/           } end
  def yes_button;  @@yes_button  ||= child(KAXButtonRole)     { |x| x.attribute(KAXTitleAttribute) == 'Yes'  } end
  def bye_button;  @@bye_button  ||= child(KAXButtonRole)     { |x| x.attribute(KAXTitleAttribute) == 'Bye!' } end
  def no_button;   @@no_button   ||= child(KAXButtonRole)     { |x| x.attribute(KAXTitleAttribute) == 'No'   } end
  def web_area;    @@web_area    ||= child("AXScrollArea")    { |x| x.attribute('AXDescription'  ) == 'Test Web Area' }.children.first end
  def text_area;   @@text_area   ||= child("AXScrollArea")    { |x| x.attributes.include?('AXIdentifier') && x.attribute('AXIdentifier') == 'Text Area' }.children.first end

  def invalid_ref
    bye_button # guarantee that it is cached
    @@dead ||= no_button.perform KAXPressAction
    bye_button
  end


  def test_equality
    assert_equal app, app
    assert_equal app, REF
    assert_equal window, window
    refute_equal app, window
  end

  ##
  # AFAICT every accessibility object **MUST** have attributes, so
  # there are no tests to check what happens when they do not exist;
  # though I am quite sure that AXElements will raise an exception.

  def test_attributes
    attrs = app.attributes
    assert_includes attrs, KAXRoleAttribute
    assert_includes attrs, KAXChildrenAttribute
    assert_includes attrs, KAXTitleAttribute
    assert_includes attrs, KAXMenuBarAttribute

    assert_empty invalid_ref.attributes, 'Dead elements should have no attrs'
  end

  def test_attribute
    assert_equal 'AXElementsTester',  window.attribute(KAXTitleAttribute  )
    assert_equal false,               window.attribute(KAXFocusedAttribute)
    assert_equal CGSize.new(555,529), window.attribute(KAXSizeAttribute   )
    assert_equal app,                 window.attribute(KAXParentAttribute )
    assert_equal 10..19,              window.attribute("AXPie"            )

    assert_nil window.attribute(KAXGrowAreaAttribute), 'KAXErrorNoValue == nil'

    assert_nil   invalid_ref.attribute(KAXRoleAttribute), 'Dead element == nil'
    assert_empty invalid_ref.attribute(KAXChildrenAttribute)

    assert_raises(ArgumentError) { app.attribute('MADE_UP_ATTR') }
  end

  def test_role
    assert_equal KAXApplicationRole, app.role
    assert_equal KAXWindowRole, window.role
  end

  def test_subrole
    assert_equal KAXStandardWindowSubrole, window.subrole
    assert_nil   web_area.subrole
  end

  def test_children
    assert_equal    app.attribute(KAXChildrenAttribute), app.children
  end

  def test_value
    assert_equal check_box.attribute(KAXValueAttribute), check_box.value
    assert_equal    slider.attribute(KAXValueAttribute), slider.value
  end

  def test_pid
    assert_equal PID, app.pid
    assert_equal PID, window.pid
    assert_equal 0, Accessibility::Element.system_wide.pid # special case
  end

  def test_invalid?
    assert_equal false, app.invalid?
    assert_equal true,  invalid_ref.invalid?
    assert_equal false, window.invalid?
  end

  def test_size_of
    assert_equal app.children.size, app.size_of(KAXChildrenAttribute)
    assert_equal 0,                 pop_up.size_of(KAXChildrenAttribute)

    assert_equal 0, invalid_ref.size_of(KAXChildrenAttribute), 'Dead == 0'
  end

  def test_writable?
    refute app.writable?    KAXTitleAttribute
    assert window.writable? KAXMainAttribute

    refute invalid_ref.writable?(KAXRoleAttribute), 'Dead is always false'
  end

  def test_set_number
    [25, 75, 50].each do |number|
      assert_equal number, slider.set(KAXValueAttribute, number)
      assert_equal number, slider.value
    end
  end

  def test_set_string
    [Time.now.to_s, ''].each do |string|
      assert_equal string, search_box.set(KAXValueAttribute, string)
      assert_equal string, search_box.value
    end
  end

  def test_set_wrapped
    text_area.set KAXValueAttribute, 'hey-o'

    text_area.set KAXSelectedTextRangeAttribute, 0..3
    assert_equal 0..3, text_area.attribute(KAXSelectedTextRangeAttribute)

    text_area.set KAXSelectedTextRangeAttribute, 1...4
    assert_equal 1..3, text_area.attribute(KAXSelectedTextRangeAttribute)
  ensure
    text_area.set KAXValueAttribute, ''
  end

  def test_set_attr_handles_errors
    assert_raises(ArgumentError) { app.set 'FAKE', true }
    assert_raises(ArgumentError) { invalid_ref.set KAXTitleAttribute, 'hi' }
  end

  def test_parameterized_attributes
    assert_empty app.parameterized_attributes

    attrs = static_text.parameterized_attributes
    assert_includes attrs, KAXStringForRangeParameterizedAttribute
    assert_includes attrs, KAXLineForIndexParameterizedAttribute
    assert_includes attrs, KAXBoundsForRangeParameterizedAttribute

    assert_empty invalid_ref.parameterized_attributes, 'Dead should always be empty'
  end

  def test_parameterized_attribute
    expected = 'My Li'

    attr = static_text.parameterized_attribute(KAXStringForRangeParameterizedAttribute, 0..4)
    assert_equal expected, attr

    attr = static_text.parameterized_attribute(KAXAttributedStringForRangeParameterizedAttribute, 0..4)
    assert_equal expected, attr.string

    assert_nil invalid_ref.parameterized_attribute(KAXStringForRangeParameterizedAttribute, 0..0),
      'dead elements should return nil for any parameterized attribute'

    # Should add a test case to test the no value case, but it will have
    # to be fabricated in the test app.

    assert_raises(ArgumentError) {
      app.parameterized_attribute(KAXStringForRangeParameterizedAttribute, 0..1)
    }
  end

  def test_actions
    assert_empty                   app.actions
    assert_equal [KAXPressAction], yes_button.actions
  end

  def test_perform_action
    2.times do # twice so it should be back where it started
      val = check_box.value
      check_box.perform KAXPressAction
      refute_equal val, check_box.value
    end

    val  = slider.value
    slider.perform KAXIncrementAction
    assert slider.value > val

    val  = slider.value
    slider.perform KAXDecrementAction
    assert slider.value < val

    assert_raises(ArgumentError) { app.perform nil }
  end

  ##
  # The keyboard simulation stuff is a bit weird...

  def test_post
    events = [[0x56,true], [0x56,false], [0x54,true], [0x54,false]]
    string = '42'

    search_box.set KAXFocusedAttribute, true
    app.post events

    assert_equal string, search_box.value

  ensure # reset for next test
    search_box.set KAXValueAttribute, ''
  end

  def test_key_rate
    assert_equal 0.009, Accessibility::Element.key_rate
    [
      [0.9,     :very_slow],
      [0.09,    :slow],
      [0.009,   :normal],
      [0.0009,  :fast],
      [0.00009, :zomg]
    ].each do |num, name|
      Accessibility::Element.key_rate = name
      assert_equal num, Accessibility::Element.key_rate
    end
  ensure
    Accessibility::Element.key_rate = :default
  end

  def test_element_at
    point   = no_button.attribute(KAXPositionAttribute)

    element = app.element_at point
    assert_equal no_button, element, "#{no_button.inspect} and #{element.inspect}"

    element = Accessibility::Element.system_wide.element_at point
    assert_equal no_button, element, "#{no_button.inspect} and #{element.inspect}"

    assert_respond_to element, :role

    # skip 'Need to find a way to guarantee an empty spot on the screen to return nil'
    # test manually for now :(
  end

  def test_application_for
    assert_equal app, Accessibility::Element.application_for(PID)

    assert_raises(ArgumentError) { Accessibility::Element.application_for 0 }
  end

  def test_system_wide
    assert_equal AXUIElementCreateSystemWide(), Accessibility::Element.system_wide
  end

  def test_application
    assert_equal app, app.application
    assert_equal app, window.application
  end

  def test_set_timeout_for
    assert_equal 10, app.set_timeout_to(10)
    assert_equal 0,  app.set_timeout_to(0)
  end



  def assert_error args, should_raise: klass, with_fragments: msgs
    e = assert_raises(klass) { (@derp || app).handle_error *args }
    assert_match /test_element.rb:272/, e.backtrace.first unless RUNNING_COMPILED
    msgs.each { |msg| assert_match msg, e.message }
  end

  def test_handle_errors
    app_inspect = Regexp.new(Regexp.escape(app.instance_variable_get(:@ref).inspect))

       assert_error [KAXErrorFailure],
      should_raise: RuntimeError,
    with_fragments: [/system failure/, app_inspect]

       assert_error [KAXErrorIllegalArgument],
      should_raise: ArgumentError,
    with_fragments: [/is not an AXUIElementRef/, app_inspect]

       assert_error [KAXErrorIllegalArgument, :cake],
      should_raise: ArgumentError,
    with_fragments: [/is not a legal argument/, /the element/, app_inspect, /cake/]

       assert_error [KAXErrorIllegalArgument, 'cake', 'chocolate'],
      should_raise: ArgumentError,
    with_fragments: [/can't get\/set "cake" with\/to "chocolate"/, app_inspect]

    p = CGPoint.new(1,3)
       assert_error [KAXErrorIllegalArgument, p, nil, nil],
      should_raise: ArgumentError,
    with_fragments: [/The point #{p.inspect}/, app_inspect]

       assert_error [KAXErrorInvalidUIElement],
      should_raise: ArgumentError,
    with_fragments: [/no longer a valid reference/, app_inspect]

       assert_error [KAXErrorInvalidUIElementObserver, :pie, :cake],
      should_raise: ArgumentError,
    with_fragments: [/no longer support/]

       assert_error [KAXErrorCannotComplete],
      should_raise: RuntimeError,
    with_fragments: [/An unspecified error/, app_inspect, /:\(/]

    @derp = Accessibility::Element.application_for pid_for 'com.apple.finder'
    def @derp.pid; false end
       assert_error [KAXErrorCannotComplete],
      should_raise: RuntimeError,
    with_fragments: [/Application for pid/, /Maybe it crashed\?/]
    @derp = nil

       assert_error [KAXErrorAttributeUnsupported, :cake],
      should_raise: ArgumentError,
    with_fragments: [/does not have/, /:cake attribute/, app_inspect]

       assert_error [KAXErrorActionUnsupported, :pie],
      should_raise: ArgumentError,
    with_fragments: [/does not have/, /:pie action/, app_inspect]

       assert_error [KAXErrorNotificationUnsupported, :cheese],
      should_raise: ArgumentError,
    with_fragments: [/no longer support/]

       assert_error [KAXErrorNotImplemented],
      should_raise: NotImplementedError,
    with_fragments: [/does not work with AXAPI/, app_inspect]

       assert_error [KAXErrorNotificationAlreadyRegistered, :lamp],
      should_raise: ArgumentError,
    with_fragments: [/no longer support/]

       assert_error [KAXErrorNotificationNotRegistered, :peas],
      should_raise: RuntimeError,
    with_fragments: [/no longer support/]

       assert_error [KAXErrorAPIDisabled],
      should_raise: RuntimeError,
    with_fragments: [/AXAPI has been disabled/]

       assert_error [KAXErrorNoValue],
      should_raise: RuntimeError,
    with_fragments: [/internal error/]

      assert_error [KAXErrorParameterizedAttributeUnsupported, :oscar],
      should_raise: ArgumentError,
    with_fragments: [/does not have/, /:oscar parameterized attribute/, app_inspect]

       assert_error [KAXErrorNotEnoughPrecision],
      should_raise: RuntimeError,
    with_fragments: [/not enough precision/, '¯\(°_o)/¯']

    exception = assert_raises(RuntimeError) { app.send(:handle_error, 0) }
    assert_match /assertion failed/, exception.message

       assert_error [99],
      should_raise: RuntimeError,
    with_fragments: [/unknown error code/, /99/, app_inspect]
  end

end


class TestToAXToRubyHooks < MiniTest::Unit::TestCase

  def test_to_ax
    value = CGPointZero.to_ax
    ptr   = Pointer.new CGPoint.type
    AXValueGetValue(value, 1, ptr)
    assert_equal CGPointZero, ptr.value, 'point makes a value'

    value = CGSizeZero.to_ax
    ptr   = Pointer.new CGSize.type
    AXValueGetValue(value, 2, ptr)
    assert_equal CGSizeZero, ptr.value, 'size makes a value'

    value = CGRectZero.to_ax
    ptr   = Pointer.new CGRect.type
    AXValueGetValue(value, 3, ptr)
    assert_equal CGRectZero, ptr.value, 'rect makes a value'

    range = CFRange.new(5, 4)
    value = range.to_ax
    ptr   = Pointer.new CFRange.type
    AXValueGetValue(value, 4, ptr)
    assert_equal range, ptr.value, 'range makes a value'

    assert_equal CFRangeMake(1,10).to_ax, (1..10  ).to_ax
    assert_equal CFRangeMake(1, 9).to_ax, (1...10 ).to_ax
    assert_equal CFRangeMake(0, 3).to_ax, (0..2   ).to_ax

    assert_raises(ArgumentError) { (1..-10).to_ax  }
    assert_raises(ArgumentError) { (-5...10).to_ax }
    assert_raises(NotImplementedError) { NSEdgeInsets.new.to_ax }

    assert_equal Object, Object.to_ax
    assert_equal 10, 10.to_ax
  end

  def test_to_ruby
    assert_equal CGPointZero,         CGPointZero        .to_ax.to_ruby
    assert_equal CGSize.new(10,10),   CGSize.new(10,10)  .to_ax.to_ruby
    assert_equal CGRectMake(1,2,3,4), CGRectMake(1,2,3,4).to_ax.to_ruby
    assert_equal 1..10,               CFRange.new(1, 10) .to_ax.to_ruby
    assert_equal Range.new(1,10),     CFRange.new(1,10)  .to_ax.to_ruby
    assert_equal Object,              Object.to_ruby
  end

end


class TestMiscCoreExtensions < MiniTest::Unit::TestCase

  def test_to_point
    p = CGPoint.new(2,3)
    assert_equal p, p.to_point

    p = CGPoint.new(1,3)
    assert_equal p, p.to_a.to_point
  end

  def test_to_size
    s = CGSize.new(2,4)
    assert_equal s, s.to_a.to_size
  end

  def test_to_rect
    r = CGRectMake(6, 7, 8, 9)
    assert_equal r, r.to_a.map(&:to_a).flatten.to_rect
  end

  def test_to_url
    site = 'http://marketcircle.com/'
    url  = site.to_url
    refute_nil url
    assert_equal NSURL.URLWithString(site), url

    file = 'file://localhost/Applications/Calculator.app/'
    url  = file.to_url
    refute_nil url
    assert_equal NSURL.fileURLWithPath('/Applications/Calculator.app/'), url

    void = "not a url at all"
    assert_nil void.to_url
  end

end
