# 1.0.0 

  * Added `Accessibility::SystemInfo` for getting information about the running system
  * Added `DSL#record` to run a screen recording of the given block (actual video!)
  * Added `Application.frontmost_application`
  * Added `Application.menu_bar_owner`
  * Added `Application.finder`
  * Added `Application.dock`
  * Added `SystemWide.focused_application` as override of built in attribute
  * Added `SystemWide.status_items`
  * Added `SystemWide.desktop`
  * Added History.markdown to track notable changes

  * Ported `mouse.rb` to C and moved code to [MRMouse](https://github.com/ferrous26/MRMouse)

  * Remove `Accessibility.application_with_bundle_identifier`; use `AX::Application.new` instead
  * Remove `Accessibility.application_with_name; use `AX::Application.new` instead
  * Remove `DSL#subtree_for`; use `Element#inspect_subtree` instead

