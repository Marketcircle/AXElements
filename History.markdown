# 0.9.0 

  * AXElements can now run on MRI as well as MacRuby

  * Added `DSL#contextual_menu` hack for finding contextual menus
  * Added `NSScreen.wakeup` to the `NSScreen` class to wake up sleeping displays
  * Added `Accessibility::SystemInfo` for getting information about the running system
    - Added a `Battery` module for querying information about the battery status
  * Added `DSL#record` to run a screen recording of the given block (actual video!)
  * Added `Application.frontmost_application`
  * Added `Application.menu_bar_owner`
  * Added `Application.finder`
  * Added `Application.dock`
  * Added `SystemWide.focused_application` as override of built in attribute
  * Added `SystemWide.status_items`
  * Added `SystemWide.desktop`
  * Added History.markdown to track notable changes
  * Added CONTRIBUTING.markdown with much less stringent guidelines

  * Moved MiniTest extensions to their own repository/gem [minitest-ax\_elements](https://github.com/AXElements/minitest-ax_elements)
  * Moved RSpec extensions to their own repository/gem [rspec-ax\_elements](https://github.com/AXElements/rspec-ax_elements)

  * Ported `mouse.rb` to C and moved code to [mouse](https://github.com/AXElements/mouse)
  * Ported `core.rb` to C and moved code to [accessibility\_core](https://github.com/AXElements/accessibility_core)
  * Ported `screen_recorder.rb` to C and moved code to [screen\_recorder](https://github.com/AXElements/screen_recorder)

  * Changed `DSL#right_click` to accept a block; block is yielded to between click down and click up events
  * Changed `AX::Element#rect` to `AX::Element#to_rect`

  * Deprecate `AX::DOCK` constant, use `AX::Application.dock` instead
  * Remove `Accessibility.application_with_bundle_identifier`; use `AX::Application.new` instead
  * Remove `Accessibility.application_with_name; use `AX::Application.new` instead
  * Remove `DSL#subtree_for`; use `Element#inspect_subtree` instead

  * Fixed fetching parameterized attributes through `Element#method_missing`
  * Fixed `Element#parameterized_attribute` automatically normalizing `Range` parameters
