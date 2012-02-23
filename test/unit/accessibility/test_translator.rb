class TestAccessibilityTranslator < MiniTest::Unit::TestCase

  TRANSLATOR = Accessibility::Translator.instance

  def test_unprefixing
    def prefix_test before, after
      assert_equal after, TRANSLATOR.unprefix(before)
    end

    prefix_test 'AXButton',               'Button'
    prefix_test 'MCAXButton',             'Button'
    prefix_test 'AXURL',                  'URL'
    prefix_test 'AXTitleUIElement',       'TitleUIElement'
    prefix_test 'AXIsApplicationRunning', 'ApplicationRunning'
    prefix_test 'AXAX',                   'AX'
    prefix_test 'Quick Look',             'QuickLook'
  end

  def test_lookup
    def lookup_test key, values, expected
      assert_equal expected, TRANSLATOR.lookup(key, with: values)
    end

    lookup_test :children,         [KAXChildrenAttribute],       KAXChildrenAttribute
    lookup_test :title_ui_element, [KAXTitleUIElementAttribute], KAXTitleUIElementAttribute
    lookup_test :focused?,         [KAXFocusedAttribute],        KAXFocusedAttribute
    lookup_test :flabbergast,      [],                           nil
    lookup_test :id,               [],                           KAXIdentifierAttribute
    lookup_test :totally_fake,     ['AXTotallyFake'],            'AXTotallyFake'
  end

  def test_rubyize
    def rubyize_test given, expected
      assert_equal Array(expected), TRANSLATOR.rubyize(Array(given))
    end

    rubyize_test KAXMainWindowAttribute,                      :main_window
    rubyize_test KAXRoleAttribute,                            :role
    rubyize_test KAXStringForRangeParameterizedAttribute,     :string_for_range
    rubyize_test [KAXSubroleAttribute, KAXChildrenAttribute], [:subrole, :children]
  end

  def test_guess_notification_for
    def notif_test actual, expected
      assert_equal expected, TRANSLATOR.guess_notification_for(actual)
    end

    notif_test 'window_created',            KAXWindowCreatedNotification
    notif_test :window_created,             KAXWindowCreatedNotification
    notif_test KAXValueChangedNotification, KAXValueChangedNotification
    notif_test 'Cheezburger',               'Cheezburger'
  end

  def test_values_are_cached
    unprefixes = TRANSLATOR.instance_variable_get :@unprefixes
    unprefixed = unprefixes['AXPieIsTheTruth']
    assert_includes unprefixes.keys, 'AXPieIsTheTruth'
    assert_equal    unprefixed, unprefixes['AXPieIsTheTruth']

    normalizations = TRANSLATOR.instance_variable_get :@normalizations
    normalized     = normalizations['AXTheAnswer']
    assert_includes normalizations.keys, 'AXTheAnswer'
    assert_equal    normalized, normalizations['AXTheAnswer']

    rubyisms = TRANSLATOR.instance_variable_get :@rubyisms
               TRANSLATOR.instance_variable_set :@values, ['AXChocolatePancake']
    rubyized = rubyisms[:chocolate_pancake]
    assert_includes rubyisms.keys, :chocolate_pancake
    assert_equal    rubyized, rubyisms[:chocolate_pancake]

    # notification guessing does not cache right now
  end

  def test_rubyize_doesnt_eat_original_data
    array = [KAXTitleAttribute, KAXMainWindowAttribute]
    TRANSLATOR.rubyize array
    assert_equal [KAXTitleAttribute, KAXMainWindowAttribute], array
  end

end
