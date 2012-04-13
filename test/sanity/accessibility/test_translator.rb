require 'test/runner'
require 'accessibility/translator'


class TestAccessibilityTranslator < MiniTest::Unit::TestCase

  TRANSLATOR = Accessibility::Translator.instance

  # trivial but important for backwards compat with Snow Leopard
  def test_identifier_const
    assert_equal 'AXIdentifier', KAXIdentifierAttribute
  end

  def test_unprefixing
    assert_equal 'Button',         TRANSLATOR.unprefix('AXButton')
    assert_equal 'URL',            TRANSLATOR.unprefix('AXURL')
    assert_equal 'TitleUIElement', TRANSLATOR.unprefix('AXTitleUIElement')
    assert_equal 'AX',             TRANSLATOR.unprefix('AXAX')
    assert_equal 'QuickLook',      TRANSLATOR.unprefix('Quick Look')
  end

  def test_cocoaification
    assert_equal KAXChildrenAttribute,       TRANSLATOR.cocoaify(:children)
    assert_equal KAXFocusedAttribute,        TRANSLATOR.cocoaify(:focused?)
    assert_equal 'AXTotallyFake',            TRANSLATOR.cocoaify(:totally_fake)

    # also check the aliases we have added
    assert_equal KAXIdentifierAttribute,       TRANSLATOR.cocoaify(:id)
    assert_equal KAXPlaceholderValueAttribute, TRANSLATOR.cocoaify(:placeholder)

    # cover this edge case :/
    assert_equal KAXIsApplicationRunningAttribute, TRANSLATOR.cocoaify(:is_application_running?)
    assert_equal KAXIsApplicationRunningAttribute, TRANSLATOR.cocoaify(:is_application_running)
    assert_equal KAXIsApplicationRunningAttribute, TRANSLATOR.cocoaify(:application_running?)
    assert_equal KAXIsApplicationRunningAttribute, TRANSLATOR.cocoaify(:application_running)
  end

  def test_cocoaification_of_acronyms
    assert_equal KAXURLAttribute,                      TRANSLATOR.cocoaify(:url)
    assert_equal KAXTitleUIElementAttribute,           TRANSLATOR.cocoaify(:title_ui_element)
    assert_equal KAXRTFForRangeParameterizedAttribute, TRANSLATOR.cocoaify(:rtf_for_range)
  end

  def test_rubyize
    assert_equal [:role],               TRANSLATOR.rubyize([KAXRoleAttribute])
    assert_equal [:main_window],        TRANSLATOR.rubyize([KAXMainWindowAttribute])
    assert_equal [:string_for_range],   TRANSLATOR.rubyize([KAXStringForRangeParameterizedAttribute])
    assert_equal [:subrole, :children], TRANSLATOR.rubyize([KAXSubroleAttribute, KAXChildrenAttribute])
  end

  def test_rubyize_doesnt_eat_original_data
    array = [KAXTitleAttribute, KAXMainWindowAttribute]
    TRANSLATOR.rubyize array
    assert_equal [KAXTitleAttribute, KAXMainWindowAttribute], array
  end

  def test_classify
    assert_equal 'Button',         TRANSLATOR.classify(:buttons)
    assert_equal 'Button',         TRANSLATOR.classify(:button)
    assert_equal 'MenuItem',       TRANSLATOR.classify(:menu_item)
    assert_equal 'FloatingWindow', TRANSLATOR.classify('floating_window')
    assert_equal 'OutlineRow',     TRANSLATOR.classify('outline_rows')
  end

  def test_singularize
    assert_equal 'button',    TRANSLATOR.singularize(:buttons)
    assert_equal 'button',    TRANSLATOR.singularize('button')
    assert_equal 'window',    TRANSLATOR.singularize(:windows)
    assert_equal 'check_box', TRANSLATOR.singularize(:check_boxes)
    assert_equal 'class',     TRANSLATOR.singularize('classes')
  end

  def test_guess_notification
    assert_equal KAXWindowCreatedNotification, TRANSLATOR.guess_notification('window_created')
    assert_equal KAXWindowCreatedNotification, TRANSLATOR.guess_notification(:window_created)
    assert_equal KAXValueChangedNotification,  TRANSLATOR.guess_notification(KAXValueChangedNotification)
    assert_equal 'Cheezburger',                TRANSLATOR.guess_notification('Cheezburger')
  end

  def test_unprefixes_are_cached
    unprefixes = TRANSLATOR.instance_variable_get :@unprefixes

    unprefixed = unprefixes['AXPieIsTheTruth']
    assert_includes unprefixes.keys, 'AXPieIsTheTruth'
    assert_equal    unprefixed, unprefixes['AXPieIsTheTruth']
  end

  def test_rubyisms_are_cached
    rubyisms = TRANSLATOR.instance_variable_get :@rubyisms

    rubyized = rubyisms['AXTheAnswer']
    assert_includes rubyisms.keys, 'AXTheAnswer'
    assert_equal    rubyized,      rubyisms['AXTheAnswer']
  end

  def test_cocoaifications_are_cached
    cocoas  = TRANSLATOR.instance_variable_get :@cocoaifications

    cocoaed = cocoas[:chocolate_pancake]
    assert_includes cocoas.keys, :chocolate_pancake
    assert_equal    cocoaed,     cocoas[:chocolate_pancake]

    cocoaed = cocoas[:chocolate_pancake?]
    assert_includes cocoas.keys, :chocolate_pancake?
    assert_equal    cocoaed,     cocoas[:chocolate_pancake?]
    # make sure we didn't kill the other guy
    assert_equal    cocoaed,     cocoas[:chocolate_pancake]
  end

  def test_classifications_are_cached
    classifications = TRANSLATOR.instance_variable_get :@classifications

    classified = TRANSLATOR.classify 'made_up_class_name'
    assert_includes classifications.keys, 'made_up_class_name'
    assert_equal    classified, classifications['made_up_class_name']
  end

  def test_singularizations_are_cached
    singulars = TRANSLATOR.instance_variable_get :@singularizations

    singular = TRANSLATOR.singularize 'buttons'
    assert_includes singulars.keys, 'buttons'
    assert_equal    singular, singulars['buttons']
  end

end
