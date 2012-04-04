require 'test/runner'
require 'accessibility/translator'


class TestAccessibilityTranslator < MiniTest::Unit::TestCase

  TRANSLATOR = Accessibility::Translator.instance

  # trivial but important for backwards compat with Snow Leopard
  def test_identifier_const
    assert_equal 'AXIdentifier', KAXIdentifierAttribute
  end

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
      assert_equal expected, TRANSLATOR.lookup(key, values)
    end

    lookup_test :children,         [KAXChildrenAttribute],       KAXChildrenAttribute
    lookup_test :title_ui_element, [KAXTitleUIElementAttribute], KAXTitleUIElementAttribute
    lookup_test :focused?,         [KAXFocusedAttribute],        KAXFocusedAttribute
    lookup_test :flabbergast,      [],                           nil
    lookup_test :totally_fake,     ['AXTotallyFake'],            'AXTotallyFake'
  end

  def test_lookup_aliases
    def lookup_test key, values, expected
      assert_equal expected, TRANSLATOR.lookup(key, values)
    end

    lookup_test :id,          [], KAXIdentifierAttribute
    lookup_test :placeholder, [], KAXPlaceholderValueAttribute
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

  def test_rubyize_doesnt_eat_original_data
    array = [KAXTitleAttribute, KAXMainWindowAttribute]
    TRANSLATOR.rubyize array
    assert_equal [KAXTitleAttribute, KAXMainWindowAttribute], array
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

  def test_classify
    def classify_test actual, expected
      assert_equal expected, TRANSLATOR.classify(actual)
    end

    classify_test :buttons,          'Button'
    classify_test :button,           'Button'
    classify_test :menu_item,        'MenuItem'
    classify_test 'floating_window', 'FloatingWindow'
    classify_test 'outline_rows',    'OutlineRow'
  end

  def test_singularize
    def singularize_test actual, expected
      assert_equal expected, TRANSLATOR.singularize(actual)
    end

    singularize_test :buttons,     'button'
    singularize_test :button,      'button'
    singularize_test :windows,     'window'
    singularize_test :check_boxes, 'check_box'
    singularize_test 'classes',    'class'
  end


  def test_unprefixes_are_cached
    unprefixes = TRANSLATOR.instance_variable_get :@unprefixes
    unprefixed = unprefixes['AXPieIsTheTruth']
    assert_includes unprefixes.keys, 'AXPieIsTheTruth'
    assert_equal    unprefixed, unprefixes['AXPieIsTheTruth']
  end

  def test_normalizations_are_cached
    normalizations = TRANSLATOR.instance_variable_get :@normalizations
    normalized     = normalizations['AXTheAnswer']
    assert_includes normalizations.keys, 'AXTheAnswer'
    assert_equal    normalized, normalizations['AXTheAnswer']
  end

  def test_rubyisms_are_cached
    rubyisms = TRANSLATOR.instance_variable_get :@rubyisms
               TRANSLATOR.instance_variable_set :@values, ['AXChocolatePancake']
    rubyized = rubyisms[:chocolate_pancake]
    assert_includes rubyisms.keys, :chocolate_pancake
    assert_equal    rubyized, rubyisms[:chocolate_pancake]

    rubyized = rubyisms[:chocolate_pancake?]
    assert_includes rubyisms.keys, :chocolate_pancake?
    assert_equal    rubyized, rubyisms[:chocolate_pancake]
    assert_equal    rubyized, rubyisms[:chocolate_pancake?]
  end

  def test_classifications_are_cached
    classifications = TRANSLATOR.instance_variable_get :@classifications

    classified      = TRANSLATOR.classify 'made_up_class_name'
    assert_includes classifications.keys, 'made_up_class_name'
    assert_equal    classified, classifications['made_up_class_name']
  end

  def test_singularizations_are_cached
    singulars = TRANSLATOR.instance_variable_get :@singularizations

    singular  = TRANSLATOR.singularize 'buttons'
    assert_includes singulars.keys, 'buttons'
    assert_equal    singular, singulars['buttons']
  end

end
