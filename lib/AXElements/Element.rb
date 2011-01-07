module AX

# @todo add a method for checking writability
# @abstract
# The abstract base class for all accessibility objects.
class Element
  include Traits::Typing


  class << self

    # Takes an AXUIElementRef and gives you some kind of accessibility object.
    #
    # The method prefers to create objects with the subrole value for an
    # accessibility object, it will use the role if there is no subrole.
    #
    # @note we have to check that the subrole value returns non-nil because
    #  sometimes an element will have a subrole but the value will be nil
    # @param [AXUIElementRef] element
    # @return [Element]
    def self.make_element element
      role    = attribute_of_element KAXRoleAttribute, element
      subrole = nil
      if attribute_names_for_element(element).include? KAXSubroleAttribute
        subrole = attribute_of_element KAXSubroleAttribute, element
      end
      choice = (subrole ? subrole : role).sub(/^AX/, '').to_sym
      AX.new_const_get(choice).new element
    end


    private

    # @param [AXUIElementRef] element
    # @return [[String]]
    def self.attribute_names_for_element element
      names = Pointer.new '^{__CFArray}'
      AXUIElementCopyAttributeNames( element, names )
      names[0]
    end

    # @param [AXUIElementRef] element
    # @return [Object]
    def self.attribute_of_element attr, element
      value = Pointer.new :id
      AXUIElementCopyAttributeValue( element, attr, value )
      value[0]
    end

  end


  # @return [[String]] A cache of available attributes and actions
  attr_reader :available_methods

  # @return [AXUIElementRef] the low level object reference
  attr_reader :ref

  # @param [AXUIElementRef] element
  def initialize element
    @ref               = element
    @available_methods = available_attributes + available_actions
  end

  # @return [[String]]
  def available_attributes
    array_ptr  = Pointer.new '^{__CFArray}'
    error_code = AXUIElementCopyAttributeNames(@ref, array_ptr)
    log_error error_code unless error_code.zero?
    array_ptr[0]
  end

  # @return [[String]]
  def available_actions
    array_ptr  = Pointer.new '^{__CFArray}'
    error_code = AXUIElementCopyActionNames(@ref, array_ptr)
    log_error error_code unless error_code.zero?
    array_ptr[0]
  end

  # @param [String] attr an attribute constant
  # @return [Object]
  def attribute attr
    result_ptr = Pointer.new :id
    error_code = AXUIElementCopyAttributeValue(@ref, attr, result_ptr)
    log_error error_code unless error_code.zero?
    # AXUIElementSetMessagingTimeout( @ref, 5.0 ) # fudge elements timeout
    # return self.attribute attribute
    result_ptr[0]
  end

  # @param [String] attr an attribute constant
  # @return [Element]
  def element_attribute attr
    Element.make_element attribute attr
  end

  # @param [String] attr
  # @return [[Element]]
  def elements_attribute attr
    attribute(attr).map { |element| Element.make_element element }
  end

  # @param [String] attribute
  # @return [NSURL]
  def url_attribute attr
    NSURL.alloc.initFileURLWithPath attribute attr
  end

  @@AXBoxType = [ nil, CGPoint, CGSize, CGRect, CFRange ]

  # @param [String] attr
  # @return [Boxed] boxed struct for klass
  def boxed_attribute attr
    value = attribute attr
    box   = AXValueGetType( value )
    ptr   = Pointer.new @@AXBoxType[box].type
    AXValueGetValue( value, box, ptr )
    ptr[0]
  end

  # Like the #perform_action method, we cannot make any assumptions
  # about the state of the program after you have set a value; at
  # least not in the general case. So, the best we can do here is
  # return true if there were no issues.
  # @param [String] attr
  # @param [Object] value
  # @return [boolean, Fixnum] true if successful, otherwise returns
  #  the error code
  def set_attribute_with_value attr, value
    error_code = AXUIElementSetAttributeValue( @ref, attr, value )
    return true if error_code.zero?
    log_error error_code
  end

  # @todo make the method wait until the action completes
  # Ideally this method would return a reference to self, but as the
  # method inherently causes state change the reference to self may no
  # longer be valid. An example of this would be pressing the close
  # button on a window.
  # @param [String] action_name
  # @return [boolean, Fixnum] true if successufl, otherwise returns the
  #  the error code
  def perform_action action_name
    error_code = AXUIElementPerformAction(@ref, action_name)
    return true if error_code.zero?
    log_error error_code
  end

  # Needed to override inherited NSObject#description. If you want a
  # description of the object try using #inspect.
  def description
    self.method_missing :description
  end

  # @todo use macirb to give all the completions to KAX and then audit
  # A big lookup table that maps nice method names to more obfuscated method
  # names in the private part of this class.
  #
  # You can add more attributes to this table at run time.
  # @return [Array] a double or triple that will be sent to self
  @@method_map = {
    ################ Fixnum
    :disclosure_level              => [:attribute, NSAccessibilityDisclosureLevelAttribute],
    :index                         => [:attribute, NSAccessibilityIndexAttribute],
    :insertion_point_line_number   => [:attribute, NSAccessibilityInsertionPointLineNumberAttribute],
    :maximum_value                 => [:attribute, NSAccessibilityMaxValueAttribute],
    :minimum_value                 => [:attribute, NSAccessibilityMinValueAttribute],
    :number_of_characters          => [:attribute, NSAccessibilityNumberOfCharactersAttribute],
    ################ [Fixnum]
    :allowed_values                => [:attribute, NSAccessibilityAllowedValuesAttribute],
    ################ Boolean
    :disclosing?                   => [:attribute, NSAccessibilityDisclosingAttribute],
    :edited?                       => [:attribute, NSAccessibilityEditedAttribute],
    :enabled?                      => [:attribute, NSAccessibilityEnabledAttribute],
    :expanded?                     => [:attribute, NSAccessibilityExpandedAttribute],
    :focused?                      => [:attribute, NSAccessibilityFocusedAttribute],
    :frontmost?                    => [:attribute, NSAccessibilityFrontmostAttribute],
    :hidden?                       => [:attribute, NSAccessibilityHiddenAttribute],
    :is_application_running?       => [:attribute, KAXIsApplicationRunningAttribute],
    :main_window?                  => [:attribute, NSAccessibilityMainAttribute],
    :minimized?                    => [:attribute, NSAccessibilityMinimizedAttribute],
    :modal?                        => [:attribute, NSAccessibilityModalAttribute],
    :selected?                     => [:attribute, NSAccessibilitySelectedAttribute],
    ################ String
    :description                   => [:attribute, NSAccessibilityDescriptionAttribute],
    :help                          => [:attribute, NSAccessibilityHelpAttribute],
    :marker_type                   => [:attribute, NSAccessibilityMarkerTypeAttribute],
    :marker_type_description       => [:attribute, NSAccessibilityMarkerTypeDescriptionAttribute],
    :menu_item_command_character   => [:attribute, KAXMenuItemCmdCharAttribute],
    :menu_item_command_glyph       => [:attribute, KAXMenuItemCmdGlyphAttribute],
    :menu_item_command_modifiers   => [:attribute, KAXMenuItemCmdModifiersAttribute],
    :menu_item_command_virtual_key => [:attribute, KAXMenuItemCmdVirtualKeyAttribute],
    :menu_item_mark_character      => [:attribute, KAXMenuItemMarkCharAttribute],
    :orientation                   => [:attribute, NSAccessibilityOrientationAttribute],
    :role                          => [:attribute, NSAccessibilityRoleAttribute],
    :role_description              => [:attribute, NSAccessibilityRoleDescriptionAttribute],
    :selected_text                 => [:attribute, NSAccessibilitySelectedTextAttribute],
    :subrole                       => [:attribute, NSAccessibilitySubroleAttribute],
    :title                         => [:attribute, NSAccessibilityTitleAttribute],
    :units                         => [:attribute, NSAccessibilityUnitsAttribute],
    :unit_description              => [:attribute, NSAccessibilityUnitDescriptionAttribute],
    :value                         => [:attribute, NSAccessibilityValueAttribute],
    ################ NSURL
    :document                      => [:url_attribute, NSAccessibilityDocumentAttribute],
    :url                           => [:url_attribute, NSAccessibilityURLAttribute],
    ################ Boxed (e.g. CGPoint)
    :position                      => [:boxed_attribute, NSAccessibilityPositionAttribute],
    :selected_text_range           => [:boxed_attribute, NSAccessibilitySelectedTextRangeAttribute],
    :shared_character_range        => [:boxed_attribute, NSAccessibilitySharedCharacterRangeAttribute],
    :size                          => [:boxed_attribute, NSAccessibilitySizeAttribute],
    :visible_character_range       => [:boxed_attribute, NSAccessibilityVisibleCharacterRangeAttribute],
    ################ Element
    :cancel_button                  => [:element_attribute, NSAccessibilityCancelButtonAttribute],
    :clear_button                   => [:element_attribute, NSAccessibilityClearButtonAttribute],
    :close_button                   => [:element_attribute, NSAccessibilityCloseButtonAttribute],
    :containing_window              => [:element_attribute, NSAccessibilityWindowAttribute],
    :decrement_button               => [:element_attribute, NSAccessibilityDecrementButtonAttribute],
    :default_button                 => [:element_attribute, NSAccessibilityDefaultButtonAttribute],
    :disclosed_by_row               => [:element_attribute, NSAccessibilityDisclosedByRowAttribute],
    :focused_application            => [:element_attribute, KAXFocusedApplicationAttribute],
    :focused_uielement              => [:element_attribute, NSAccessibilityFocusedUIElementAttribute],
    :focused_window                 => [:element_attribute, NSAccessibilityFocusedWindowAttribute],
    :grow_area                      => [:element_attribute, NSAccessibilityGrowAreaAttribute],
    :header                         => [:element_attribute, NSAccessibilityHeaderAttribute],
    :horizontal_scroll_bar          => [:element_attribute, NSAccessibilityHorizontalScrollBarAttribute],
    :increment_button               => [:element_attribute, NSAccessibilityIncrementButtonAttribute],
    :main_window                    => [:element_attribute, NSAccessibilityMainWindowAttribute],
    :minimize_button                => [:element_attribute, NSAccessibilityMinimizeButtonAttribute],
    :menu_bar                       => [:element_attribute, NSAccessibilityMenuBarAttribute],
    :menu_item_primary_uielement    => [:element_attribute, KAXMenuItemPrimaryUIElementAttribute],
    :overflow_button                => [:element_attribute, NSAccessibilityOverflowButtonAttribute],
    :parent                         => [:element_attribute, NSAccessibilityParentAttribute],
    :proxy                          => [:element_attribute, NSAccessibilityProxyAttribute],
    :search_button                  => [:element_attribute, NSAccessibilitySearchButtonAttribute],
    :title_uielement                => [:element_attribute, NSAccessibilityTitleUIElementAttribute],
    :toolbar_button                 => [:element_attribute, NSAccessibilityToolbarButtonAttribute],
    :top_level_uielement            => [:element_attribute, NSAccessibilityTopLevelUIElementAttribute],
    :vertical_scroll_bar            => [:element_attribute, NSAccessibilityVerticalScrollBarAttribute],
    :zoom_button                    => [:element_attribute, NSAccessibilityZoomButtonAttribute],
    ################ Setters
    :get_focus                      => [:set_attribute_with_value, NSAccessibilityFocusedAttribute, true],
    :value=                         => [:set_attribute_with_value, NSAccessibilityValueAttribute],
    ################ Actions
    :cancel                         => [:perform_action, NSAccessibilityCancelAction],
    :confirm                        => [:perform_action, NSAccessibilityConfirmAction],
    :decrement                      => [:perform_action, NSAccessibilityDecrementAction],
    :delete                         => [:perform_action, NSAccessibilityDeleteAction],
    :increment                      => [:perform_action, NSAccessibilityIncrementAction],
    :pick                           => [:perform_action, NSAccessibilityPickAction],
    :press                          => [:perform_action, NSAccessibilityPressAction],
    :raise                          => [:perform_action, NSAccessibilityRaiseAction],
    :show_menu                      => [:perform_action, NSAccessibilityShowMenuAction],
    ################ [Element]
    :children                       => [:elements_attribute, NSAccessibilityChildrenAttribute],
    :columns                        => [:elements_attribute, NSAccessibilityColumnsAttribute],
    :column_titles                  => [:elements_attribute, NSAccessibilityColumnTitlesAttribute],
    :contents                       => [:elements_attribute, NSAccessibilityContentsAttribute],
    :disclosed_rows                 => [:elements_attribute, NSAccessibilityDisclosedRowsAttribute],
    :marker_uielements              => [:elements_attribute, NSAccessibilityMarkerUIElementsAttribute],
    :next_contents                  => [:elements_attribute, NSAccessibilityNextContentsAttribute],
    :previous_contents              => [:elements_attribute, NSAccessibilityPreviousContentsAttribute],
    :rows                           => [:elements_attribute, NSAccessibilityRowsAttribute],
    :shown_menu_ui_element          => [:elements_attribute, NSAccessibilityShownMenuAttribute],
    :selected_children              => [:elements_attribute, NSAccessibilitySelectedChildrenAttribute],
    :selected_columns               => [:elements_attribute, NSAccessibilitySelectedColumnsAttribute],
    :selected_rows                  => [:elements_attribute, NSAccessibilitySelectedRowsAttribute],
    :serves_as_title_for_uielements => [:elements_attribute, NSAccessibilityServesAsTitleForUIElementsAttribute],
    :shared_text_uielements         => [:elements_attribute, NSAccessibilitySharedTextUIElementsAttribute],
    :splitters                      => [:elements_attribute, NSAccessibilitySplittersAttribute],
    :tabs                           => [:elements_attribute, NSAccessibilityTabsAttribute],
    :visible_children               => [:elements_attribute, NSAccessibilityVisibleChildrenAttribute],
    :visible_columns                => [:elements_attribute, NSAccessibilityVisibleColumnsAttribute],
    :visible_rows                   => [:elements_attribute, NSAccessibilityVisibleRowsAttribute],
    :windows                        => [:elements_attribute, NSAccessibilityWindowsAttribute],
  }

  # We use #method missing to dynamically handle requests to get elements
  # that are children of the current element or attributes of the current
  # element. Basically, everything that is not a convenience method is routed
  # through here to figure things out for you dynamically.
  #
  # Since this method does both types of dynamic lookup, one has to take
  # priority over the other. Attributes comes first, then children element
  # search.
  #
  # When you are looking up an attribute this method will first make sure that
  # the current element has the required attribute, then it maps your call to
  # the more abstract wrapper class.
  #
  # Should the attribute lookup fail, the method will then try search for an
  # element that is a child of the current element. In this case, if the method
  # name ends with an 's' it is assumed you wanted an array of elements that
  # match the criteria and no 's' means you want the first one that is found.
  #
  # The first crieteria is the name of the method, mangled matched against the
  # existing classes in the AX namespace. Additional criteria are taken from
  # the arguments to the method, and are assumed to be key-value pairs with
  # the key being an attribute and the value being the value of the attribute.
  #
  # @example Simple single element lookup
  #  daylite = Application.daylite 3
  #  window  = daylite.focused_window
  #  window.button.press # => You want the first Button that is found
  # @example Simple multi-element lookup
  #  window.text_fields # => You want all the TextField objects found
  # @example Filtered single element lookup
  #  window.button(title:'Log In') # => First Button with a title of 'Log In'
  # @example Filtered multi-element lookup
  #  window.buttons(title:'New Project')
  # @example Contrived multi-element lookup
  #  window.buttons(title:'New Project', role:KAXButtonRole)
  #
  # While the code in here is a bit ugly, I justify it by the fact that this
  # method will be THE hotspot during run time due to the way the system has
  # been designed, and so some attempt at making performant code needs to
  # be made.
  #
  # @note Some attribute names don't map consistently from Apple's
  #  documentation because it would have caused a clash with the two
  #  systems used for attribute lookup and searching/filtering.
  #
  # @todo print UI tree when method is not found
  # @todo allow element lookup for array returning attributes other than
  #  the children method
  # @todo allow regex matching when filtering string attributes
  # @todo if the method corresponds to something that returns an array
  #  and so it should allow optional filtering
  # @raise NoMethodError
  def method_missing(method, *args)
    if (set = @@method_map[method]) && (@available_methods.index set[1])
      return self.send *set, *args
    end

    # check to avoid an infinite loop
    if @available_methods.index NSAccessibilityChildrenAttribute
      elements = self.children
      args.unshift class:(AX.plural_const_get(method.to_s.camelize!))

      args.each { |map| map = map.shift
        elements = elements.select { |element| element.send(map[0]) == map[1] }
      }

      return elements if method.to_s.match /s$/
      return elements.first
    end

    raise NoMethodError, "Got to the end when trying ##{method} on a #{self.class}. Typo?"
  end


  protected

  # A mapping of the AXError constants to human readable strings.
  # @return [String]
  @@AXError = {
    KAXErrorFailure                           => 'Generic Failure',
    KAXErrorIllegalArgument                   => 'Illegal Argument',
    KAXErrorInvalidUIElement                  => 'Invalid UI Element',
    KAXErrorInvalidUIElementObserver          => 'Invalid UI Element Observer',
    KAXErrorCannotComplete                    => 'Cannot Complete',
    KAXErrorAttributeUnsupported              => 'Attribute Unsupported',
    KAXErrorActionUnsupported                 => 'Action Unsupported',
    KAXErrorNotificationUnsupported           => 'Notification Unsupported',
    KAXErrorNotImplemented                    => 'Not Implemented',
    KAXErrorNotificationAlreadyRegistered     => 'Notification Already Registered',
    KAXErrorNotificationNotRegistered         => 'Notification Not Registered',
    KAXErrorAPIDisabled                       => 'API Disabled',
    KAXErrorNoValue                           => 'No Value',
    KAXErrorParameterizedAttributeUnsupported => 'Parameterized Attribute Unsupported',
    KAXErrorNotEnoughPrecision                => 'Not Enough Precision',
  }

  # Uses the call stack and error code to log a message that might be helpful
  # in debugging.
  # @param [Fixnum] error_code an AXError value
  # @return [Fixnum] the error code that was passed to this method
  def log_error error_code
    error = @@AXError[error_code] || 'UNKNOWN ERROR CODE'
    NSLog("[#{error} (#{error_code})] while trying something on a #{self.role}:")
    NSLog("Attributes and actions that were available: #{self.available_methods}")
    NSLog("Backtrace: #{caller.description}")
    error_code
  end
end
end
