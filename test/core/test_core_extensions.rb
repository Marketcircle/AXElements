class TestNSArrayAccessors < MiniTest::Unit::TestCase

  def test_second_returns_second_from_array
    [[1,2],[:one,:two]].each { |array|
      assert_equal array.last, NSArray.arrayWithArray(array).second
      assert_equal array.last, array.second
    }
  end

  def test_second_returns_nil_from_array_of_one
    [[1], [:one]].each { |array|
      assert_nil NSArray.arrayWithArray(array).second
      assert_nil array.second
    }
  end

  def test_second_returns_second_from_array
    [[1,2,3],[:one,:two,:three]].each { |array|
      assert_equal array.last, NSArray.arrayWithArray(array).third
      assert_equal array.last, array.third
    }
  end

  def test_second_returns_nil_from_array_of_two
    [[1,2], [:one,:two]].each { |array|
      assert_nil NSArray.arrayWithArray(array).third
      assert_nil array.third
    }
  end

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

  def test_nil_if_empty_string
    assert_nil ''.camelize!
  end

end


class TestNSStringPredicate < MiniTest::Unit::TestCase

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
