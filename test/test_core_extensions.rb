require 'helper'

class TestArrayCoreExtensions < MiniTest::Unit::TestCase
  def test_method_missing_delegates_up_if_array_is_not_composed_of_elements
    assert_raises NoMethodError do [1,2].title_ui_element end
  end

  def test_method_missing_maps_method_across_array
    assert_instance_of String, AX::DOCK.list.application_dock_items.role.sample
  end

  def test_should_not_singularize_methods_that_are_meant_to_be_plural
    refute_empty AX::DOCK.list.application_dock_items.children.compact
  end

  def test_should_singularize_methods_that_do_not_normally_exist
    [:roles, :titles, :parents, :positions, :sizes, :urls].each { |attribute|
      refute_empty AX::DOCK.list.application_dock_items.send(attribute).compact
    }
  end
end

class TestStringCoreExtensions < MiniTest::Unit::TestCase
  def test_camelize_bang_takes_snake_case_string_and_makes_it_camel_case
    assert_equal 'AMethodName', 'a_method_name'.camelize!
    assert_equal 'MethodName',  'method_name'.camelize!
    assert_equal 'Name',        'name'.camelize!
  end

  def test_camelize_bany_takes_camel_case_and_does_nothing
    assert_equal 'AMethodName', 'AMethodName'.camelize!
    assert_equal 'MethodName',  'MethodName'.camelize!
    assert_equal 'Name',        'Name'.camelize!
  end

  def test_predicate_returns_true_if_string_ends_with_a_question_mark
    assert 'test?'.predicate?
  end

  def test_predicate_returns_false_if_the_string_does_not_end_with_a_question_mark
    refute 'test'.predicate?
    refute 'tes?t'.predicate?
    refute 'te?st'.predicate?
    refute 't?est'.predicate?
    refute '?test'.predicate?
  end
end
