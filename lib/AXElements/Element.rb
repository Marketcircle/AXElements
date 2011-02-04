module AX

# @abstract
# The abstract base class for all accessibility objects.
class Element

  include Traits::Clicking
  include Traits::Notifications


  # This array is order-sensitive, which is why there is a
  # nil object at index 0.
  # @return [Class,nil]
  AXBoxTypes = [ nil, CGPoint, CGSize, CGRect, CFRange ]


  class << self

    # @note we have to check that the subrole value returns non-nil because
    #  sometimes an element will have a subrole but the value will be nil
    # Takes an AXUIElementRef and gives you some kind of accessibility object.
    #
    # This method prefers to choose a class type based on the subrole value for
    # an accessibility object, and it will use the role if there is no subrole.
    # @param [AXUIElementRef] element
    # @return [Element]
    def make_element element
      role    = attribute_of_element KAXRoleAttribute, element
      subrole = nil
      if attributes(element).include? KAXSubroleAttribute
        subrole = attribute_of_element KAXSubroleAttribute, element
      end
      choice = (subrole || role).sub(/^(MC)?AX/, '')
      AX.new_const_get(choice).new element
    end


    private

    # @param [AXUIElementRef] element
    # @return [Array<String>]
    def attributes element
      names = Pointer.new '^{__CFArray}'
      AXUIElementCopyAttributeNames( element, names )
      names[0]
    end

    # @param [AXUIElementRef] element
    # @return [Object]
    def attribute_of_element attr, element
      value = Pointer.new :id
      AXUIElementCopyAttributeValue( element, attr, value )
      value[0]
    end

  end


  # @return [Array<String>] A cache of available attributes and actions
  attr_reader :methods

  # @return [AXUIElementRef] the low level object reference
  attr_reader :ref

  # @param [AXUIElementRef] element
  def initialize element
    @ref     = element
    @methods = attributes + actions
  end

  # @return [Fixnum]
  def pid
    @pid ||= ( ptr = Pointer.new 'i' ; AXUIElementGetPid( @ref, ptr ) ; ptr[0] )
  end

  # @return [Array<String>]
  def attributes
    array_ptr  = Pointer.new '^{__CFArray}'
    log AXUIElementCopyAttributeNames( @ref, array_ptr )
    array_ptr[0]
  end

  # @return [Array<String>]
  def actions
    array_ptr  = Pointer.new '^{__CFArray}'
    log AXUIElementCopyActionNames( @ref, array_ptr )
    array_ptr[0]
  end

  # Check the writability of a particular attribute
  # @param [String] attr
  # @return [Boolean]
  def attribute_writable? attr
    ptr = Pointer.new :id
    error_code = AXUIElementElementIsAttributeSettable( @ref, attr, ptr )
    log error_code, attr
    ptr[0]
  end

  # @param [String] attr an attribute constant
  # @return [Object,nil]
  def attribute attr
    result_ptr = Pointer.new :id
    error_code = AXUIElementCopyAttributeValue( @ref, attr, result_ptr )
    log error_code, attr
    result_ptr[0]
  end

  # @param [String] attr an attribute constant
  # @return [AX::Element,nil]
  def element_attribute attr
    value = attribute attr
    return nil unless value
    Element.make_element value
  end

  # @param [String] attr an attribute constant
  # @return [Array<AX::Element>]
  def elements_attribute attr
    value = attribute attr
    return [] unless value
    value.map { |element| Element.make_element element }
  end

  # @param [String] attr an attribute constant
  # @return [Boxed,nil]
  def boxed_attribute attr
    value = attribute attr
    return nil unless value
    box   = AXValueGetType( value )
    ptr   = Pointer.new AXBoxTypes[box].type
    AXValueGetValue( value, box, ptr )
    ptr[0]
  end

  # Like the {#perform_action} method, we cannot make any assumptions
  # about the state of the program after you have set a value; at
  # least not in the general case. So, the best we can do here is
  # return true if there were no issues.
  # @param [String] attr
  # @return [Boolean] true if successful, otherwise false
  def set_attribute_with_value attr, value
    error_code = AXUIElementSetAttributeValue( @ref, attr, value )
    log( error_code, [attr, value] ) == 0
  end

  # Ideally this method would return a reference to self, but as the
  # method inherently causes state change the reference to self may no
  # longer be valid. An example of this would be pressing the close
  # button on a window.
  # @param [String] action_name
  # @return [Boolean] true if successful, otherwise false
  def perform_action action_name
    error_code = AXUIElementPerformAction( @ref, action_name )
    log( error_code, action_name ) == 0
  end

  # Needed to override inherited NSObject#description. If you want a
  # description of the object try using #inspect.
  def description
    self.method_missing :description
  end

  # A big lookup table that maps nice method names to more obfuscated method
  # names in the private part of this class.
  #
  # You can add more attributes to this table at run time.
  # @return [Array<Symbol, String, Boolean>] a pair or triple that will be sent to self
  @@method_map = {
    #                             Fixnum
                 disclosure_level:[:attribute, NSAccessibilityDisclosureLevelAttribute],
                            index:[:attribute, NSAccessibilityIndexAttribute],
      insertion_point_line_number:[:attribute, NSAccessibilityInsertionPointLineNumberAttribute],
                    maximum_value:[:attribute, NSAccessibilityMaxValueAttribute],
                    minimum_value:[:attribute, NSAccessibilityMinValueAttribute],
             number_of_characters:[:attribute, NSAccessibilityNumberOfCharactersAttribute],
    #                             Array<Fixnum>
                   allowed_values:[:attribute, NSAccessibilityAllowedValuesAttribute],
    #                             Boolean
                       disclosing?:[:attribute, NSAccessibilityDisclosingAttribute],
                           edited?:[:attribute, NSAccessibilityEditedAttribute],
                          enabled?:[:attribute, NSAccessibilityEnabledAttribute],
                         expanded?:[:attribute, NSAccessibilityExpandedAttribute],
                          focused?:[:attribute, NSAccessibilityFocusedAttribute],
                        frontmost?:[:attribute, NSAccessibilityFrontmostAttribute],
                           hidden?:[:attribute, NSAccessibilityHiddenAttribute],
              application_running?:[:attribute, KAXIsApplicationRunningAttribute],
                      main_window?:[:attribute, NSAccessibilityMainAttribute],
                        minimized?:[:attribute, NSAccessibilityMinimizedAttribute],
                            modal?:[:attribute, NSAccessibilityModalAttribute],
                         selected?:[:attribute, NSAccessibilitySelectedAttribute],
    #                              String
                       description:[:attribute, NSAccessibilityDescriptionAttribute],
                              help:[:attribute, NSAccessibilityHelpAttribute],
                       marker_type:[:attribute, NSAccessibilityMarkerTypeAttribute],
           marker_type_description:[:attribute, NSAccessibilityMarkerTypeDescriptionAttribute],
       menu_item_command_character:[:attribute, KAXMenuItemCmdCharAttribute],
           menu_item_command_glyph:[:attribute, KAXMenuItemCmdGlyphAttribute],
       menu_item_command_modifiers:[:attribute, KAXMenuItemCmdModifiersAttribute],
     menu_item_command_virtual_key:[:attribute, KAXMenuItemCmdVirtualKeyAttribute],
          menu_item_mark_character:[:attribute, KAXMenuItemMarkCharAttribute],
                       orientation:[:attribute, NSAccessibilityOrientationAttribute],
                              role:[:attribute, NSAccessibilityRoleAttribute],
                  role_description:[:attribute, NSAccessibilityRoleDescriptionAttribute],
                     selected_text:[:attribute, NSAccessibilitySelectedTextAttribute],
                           subrole:[:attribute, NSAccessibilitySubroleAttribute],
                             title:[:attribute, NSAccessibilityTitleAttribute],
                             units:[:attribute, NSAccessibilityUnitsAttribute],
                  unit_description:[:attribute, NSAccessibilityUnitDescriptionAttribute],
                             value:[:attribute, NSAccessibilityValueAttribute],
           quick_search_group_name:[:attribute, 'MCAXQuickSearchGroupName'],
    #                              NSURL
                          document:[:attribute, NSAccessibilityDocumentAttribute],
                               url:[:attribute, NSAccessibilityURLAttribute],
    #                              Boxed (e.g. CGPoint)
                          position:[:boxed_attribute, NSAccessibilityPositionAttribute],
               selected_text_range:[:boxed_attribute, NSAccessibilitySelectedTextRangeAttribute],
            shared_character_range:[:boxed_attribute, NSAccessibilitySharedCharacterRangeAttribute],
                              size:[:boxed_attribute, NSAccessibilitySizeAttribute],
           visible_character_range:[:boxed_attribute, NSAccessibilityVisibleCharacterRangeAttribute],
    #                              Element
                     cancel_button:[:element_attribute, NSAccessibilityCancelButtonAttribute],
                      clear_button:[:element_attribute, NSAccessibilityClearButtonAttribute],
                      close_button:[:element_attribute, NSAccessibilityCloseButtonAttribute],
                 containing_window:[:element_attribute, NSAccessibilityWindowAttribute],
                  decrement_button:[:element_attribute, NSAccessibilityDecrementButtonAttribute],
                    default_button:[:element_attribute, NSAccessibilityDefaultButtonAttribute],
                  disclosed_by_row:[:element_attribute, NSAccessibilityDisclosedByRowAttribute],
               focused_application:[:element_attribute, KAXFocusedApplicationAttribute],
                 focused_uielement:[:element_attribute, NSAccessibilityFocusedUIElementAttribute],
                    focused_window:[:element_attribute, NSAccessibilityFocusedWindowAttribute],
                         grow_area:[:element_attribute, NSAccessibilityGrowAreaAttribute],
                            header:[:element_attribute, NSAccessibilityHeaderAttribute],
             horizontal_scroll_bar:[:element_attribute, NSAccessibilityHorizontalScrollBarAttribute],
                  increment_button:[:element_attribute, NSAccessibilityIncrementButtonAttribute],
                       main_window:[:element_attribute, NSAccessibilityMainWindowAttribute],
                   minimize_button:[:element_attribute, NSAccessibilityMinimizeButtonAttribute],
                          menu_bar:[:element_attribute, NSAccessibilityMenuBarAttribute],
       menu_item_primary_uielement:[:element_attribute, KAXMenuItemPrimaryUIElementAttribute],
                   overflow_button:[:element_attribute, NSAccessibilityOverflowButtonAttribute],
                            parent:[:element_attribute, NSAccessibilityParentAttribute],
                             proxy:[:element_attribute, NSAccessibilityProxyAttribute],
                     search_button:[:element_attribute, NSAccessibilitySearchButtonAttribute],
                   title_uielement:[:element_attribute, NSAccessibilityTitleUIElementAttribute],
                    toolbar_button:[:element_attribute, NSAccessibilityToolbarButtonAttribute],
               top_level_uielement:[:element_attribute, NSAccessibilityTopLevelUIElementAttribute],
               vertical_scroll_bar:[:element_attribute, NSAccessibilityVerticalScrollBarAttribute],
                       zoom_button:[:element_attribute, NSAccessibilityZoomButtonAttribute],
    #                              Array<Element>
                          children:[:elements_attribute, NSAccessibilityChildrenAttribute],
                           columns:[:elements_attribute, NSAccessibilityColumnsAttribute],
                     column_titles:[:elements_attribute, NSAccessibilityColumnTitlesAttribute],
                          contents:[:elements_attribute, NSAccessibilityContentsAttribute],
                    disclosed_rows:[:elements_attribute, NSAccessibilityDisclosedRowsAttribute],
                 marker_uielements:[:elements_attribute, NSAccessibilityMarkerUIElementsAttribute],
                     next_contents:[:elements_attribute, NSAccessibilityNextContentsAttribute],
                 previous_contents:[:elements_attribute, NSAccessibilityPreviousContentsAttribute],
                              rows:[:elements_attribute, NSAccessibilityRowsAttribute],
             shown_menu_ui_element:[:elements_attribute, NSAccessibilityShownMenuAttribute],
                 selected_children:[:elements_attribute, NSAccessibilitySelectedChildrenAttribute],
                  selected_columns:[:elements_attribute, NSAccessibilitySelectedColumnsAttribute],
                     selected_rows:[:elements_attribute, NSAccessibilitySelectedRowsAttribute],
    serves_as_title_for_uielements:[:elements_attribute, NSAccessibilityServesAsTitleForUIElementsAttribute],
            shared_text_uielements:[:elements_attribute, NSAccessibilitySharedTextUIElementsAttribute],
                         splitters:[:elements_attribute, NSAccessibilitySplittersAttribute],
                              tabs:[:elements_attribute, NSAccessibilityTabsAttribute],
                  visible_children:[:elements_attribute, NSAccessibilityVisibleChildrenAttribute],
                   visible_columns:[:elements_attribute, NSAccessibilityVisibleColumnsAttribute],
                      visible_rows:[:elements_attribute, NSAccessibilityVisibleRowsAttribute],
                           windows:[:elements_attribute, NSAccessibilityWindowsAttribute],
    #                              Setters
                         get_focus:[:set_attribute_with_value, NSAccessibilityFocusedAttribute, true],
                         :value= =>[:set_attribute_with_value, NSAccessibilityValueAttribute],
    #                              Actions
                            cancel:[:perform_action, NSAccessibilityCancelAction],
                           confirm:[:perform_action, NSAccessibilityConfirmAction],
                         decrement:[:perform_action, NSAccessibilityDecrementAction],
                            delete:[:perform_action, NSAccessibilityDeleteAction],
                         increment:[:perform_action, NSAccessibilityIncrementAction],
                              pick:[:perform_action, NSAccessibilityPickAction],
                             press:[:perform_action, NSAccessibilityPressAction],
                             raise:[:perform_action, NSAccessibilityRaiseAction],
                         show_menu:[:perform_action, NSAccessibilityShowMenuAction]
  }


  # @todo allow regex matching when filtering string attributes
  # @note Some attribute names don't map consistently from Apple's
  #  documentation because it would have caused a clash with the two
  #  systems used for attribute lookup and searching/filtering.
  #
  # We use {#method missing} to dynamically handle requests to lookup
  # attributes and to dynamically search for elements in the view
  # hierarchy. Everything that is not a convenience method is routed
  # through here to figure things out for you dynamically.
  #
  # Since this method does two types of dynamic lookup, one has to take
  # priority over the other. Attribute lookups come first, and if that
  # fails a search through the hierarchy will begin.
  #
  # When you are looking up an attribute, this method will first make
  # sure that the current element has the required attribute, then it
  # will try to map the method name to an actual attribute name (listed
  # in {@@method_map}) in order to call a lower level method (which in
  # turn calls the actual CoreFoundation API).
  #
  # Should the attribute lookup fail, the method will then try search
  # for an element that is a descendant of the current element by way of
  # a breadth first search through the view hierarchy subtree rooted at
  # the current node.
  #
  # There are two features of the search that are important with regards
  # results of the search: pluralization and filtering.
  #
  # Pluralization is simply when an 's' is appended to the method call
  # causing the lookup to assume you wanted every element in the view
  # hierarchy that meets the filtering criteria. This causes the lookup
  # to be very slow (~1 second) and is meant more for prototying tests
  # and debugging broken tests. If you do not pluralize, then the first
  # element that meets all the filtering criteria will be returned.
  #
  # Filtering is the important part of a lookup. There is one default
  # filter which filters based on the class of the element, and the class
  # name is taken from method name that triggered {#method_missing}. Other
  # filtering criteria is optional, but often helpful in finding a
  # specific element. Right now the only types of filtering criteria that
  # work are attribute filters, which lookup attributes on the element
  # being inspected and compare them to an expected value. You can attach
  # as many attribute filters as you want.
  #
  # @example Attribute lookup of another element
  #  mail   = AX::Application.application_with_bundle_identifier 'com.apple.mail'
  #  window = mail.focused_window
  # @example Attribute lookup of element properties
  #  window.title
  # @example Simple single element lookup
  #  window.button # => You want the first Button that is found
  # @example Simple multi-element lookup
  #  window.text_fields # => You want all the TextField objects found
  # @example Additional filters for a single element lookup
  #  window.button(title:'Log In') # => First Button with a title of 'Log In'
  # @example Additional filters for a multi-element lookup
  #  window.buttons(title:'New Project')
  # @example Contrived multi-element lookup
  #  window.buttons(title:'New Project', enabled?:true)
  # @raise NoMethodError
  def method_missing method, *args

    if (action = @@method_map[method]) && (@methods.index action[1])
      return self.send *action, *args
    end

    # NOW WE TRY TO DO A SEARCH

    # check to avoid an infinite loop
    if @methods.index KAXChildrenAttribute
      elements       = self.children # seed the search array
      search_results = []
      filters        = args[0] || {}
      class_const    = method.to_s.camelize!

      until elements.empty?
        element          = elements.shift
        primary_filter ||= AX.plural_const_get class_const

        elements.concat(element.children) if element.methods.include? KAXChildrenAttribute

        next unless element.class == primary_filter

        # disabled until MacRuby ticket #1139 is resolved
        # next unless filters.each_pair { |filter_attribute, value|
        #   break unless element.send(filter_attribute) == value
        # }
        next unless filters.inject true do |previous, filter|
          previous && (element.send(filter[0]) == filter[1])
        end

        return element unless method.to_s.match(/s$/)
        search_results << element
      end

      return search_results if method.to_s.match /s$/
      return search_results.first
    end

    AX.log.debug "##{method} attr doesn't exist and this #{self.class} doesn't have children"
    super
  end


  protected

  # A mapping of the AXError constants to human readable strings.
  # @return [Hash{Fixnum => String}]
  AXError = {
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

  # @todo print view hierarchy
  # Uses the call stack and error code to log a message that might be helpful
  # in debugging.
  # @param [Fixnum] error_code an AXError value
  # @param [#to_s] method_args an AXError value
  # @return [Fixnum] the error code that was passed to this method
  def log error_code, method_args = 'unspecified method'
    return 0 if error_code.zero?
    error = AXError[error_code] || 'UNKNOWN ERROR CODE'
    AX.log.warn "[#{error} (#{error_code})] while trying #{method_args} on a #{self.role}"
    AX.log.info "Attributes and actions that were available: #{self.methods.inspect}"
    AX.log.debug "Backtrace: #{caller.description}"
    error_code
  end
end
end
