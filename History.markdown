# 1.0.0 

  * Added History.markdown to track notable changes

  * Ported `mouse.rb` to C and moved code to [MRMouse](https://github.com/ferrous26/MRMouse)

  * Remove `Accessibility.application_with_bundle_identifier`; use `AX::Application.new` instead
  * Remove `Accessibility.application_with_name; use `AX::Application.new` instead
  * Remove `DSL#subtree_for`; use `Element#inspect_subtree` instead

