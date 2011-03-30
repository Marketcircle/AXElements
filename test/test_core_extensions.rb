class TestNSArrayMethodMissing < MiniTest::Unit::TestCase
  ELEMENTS = AX::DOCK.list.application_dock_items
  def test_delegates_up_if_array_is_not_composed_of_elements
    assert_raises NoMethodError do [1,2].title_ui_element end
  end
  # @todo this test is too invasive right now
  # def test_actions_are_executed
  # end
  def test_not_plural_not_predicate
    refute_empty ELEMENTS.url.compact
  end
  def test_plural_not_predicate
    refute_empty ELEMENTS.children.compact
  end
  def test_artificially_plural_not_predicate
    refute_empty ELEMENTS.urls.compact
  end
  def test_not_plural_predicate
    refute_empty ELEMENTS.application_running?.compact
  end
  # predicate names are general past tense and sound silly when
  # I try to pluralize them, so these tests are not needed
  # def test_plural_predicate
  # end
  # def test_artificially_plural_predicate
  # end
end

class TestNSMutableStringCamelizeBang < MiniTest::Unit::TestCase
  def test_takes_snake_case_string_and_makes_it_camel_case
    assert_equal 'AMethodName', 'a_method_name'.camelize!
    assert_equal 'MethodName',  'method_name'.camelize!
    assert_equal 'Name',        'name'.camelize!
  end
  def test_takes_camel_case_and_does_nothing
    assert_equal 'AMethodName', 'AMethodName'.camelize!
    assert_equal 'MethodName',  'MethodName'.camelize!
    assert_equal 'Name',        'Name'.camelize!
  end
end

class TestNSMutableStringPredicate < MiniTest::Unit::TestCase
  def test_true_if_string_ends_with_a_question_mark
    assert 'test?'.predicate?
  end
  def test_false_if_the_string_does_not_end_with_a_question_mark
    refute 'tes?t'.predicate?
    refute 'te?st'.predicate?
    refute 't?est'.predicate?
    refute '?test'.predicate?
  end
  def test_false_if_the_string_has_no_question_mark
    refute 'test'.predicate?
  end
end

class TestCGPointCarbonizeBang < MiniTest::Unit::TestCase
  def test_origin_in_cocoa_is_bottom_left_in_carbon
    point = CGPointZero.dup.carbonize!
    assert_equal NSScreen.mainScreen.frame.size.height, point.y
  end
  # @todo is this test too naively implemented?
  def test_middle_of_screen_is_still_middle_of_screen
    frame = NSScreen.mainScreen.frame
    point = frame.origin
    point.x = frame.size.width / 2
    point.y = frame.size.height / 2
    assert_equal point, point.dup.carbonize!
  end
  # @todo this test needs to be broken up
  def test_works_when_point_is_on_a_secondary_screen
    skip 'You need a second monitor for this test' if NSScreen.screens.size < 2
    main_screen_width = NSScreen.mainScreen.frame.size.width
    NSScreen.screens.each { |screen|
      if screen.frame.origin.x >= main_screen_width || screen.frame.origin.x < 0
        point = CGPoint.new(screen.frame.origin.x,0).carbonize!
        assert_equal screen.frame.size.height, point.y
      end
      if screen.frame.origin.y < 0
        point = CGPoint.new(0,screen.frame.origin.y).carbonize!
        assert_equal screen.frame.size.height, point.y
      end
    }
  end
end
