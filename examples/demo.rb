require 'rubygems'
require 'ax_elements'

# Highlight objects that the mouse will move to
Accessibility.debug = true

# Get a reference to the Finder and bring it to the front
finder = app_with_bundle_identifier 'com.apple.finder'
set_focus_to finder

# Open a new window
type "\\COMMAND+n"
sleep 1 # pause for "slow motion"

# Find and click the "Applications" item in the sidebar
window = finder.main_window
click window.outline.row(static_text: { value: 'Applications' })

# Find the Utilities folder
utilities = window.row(text_field: { filename: 'Utilities' })
scroll_to utilities
double_click utilities

# Wait for the folder to open and find the Activity Monitor app
app = wait_for :text_field, ancestor: window, filename: /Activity Monitor/
scroll_to app
click app

# Bring up QuickLook
type " "
sleep 1 # pause for "slow motion"

# Click the Quick Look button that opens the app
click finder.quick_look.button(id: 'QLControlOpen')
sleep 1 # pause for "slow motion"

# Get a reference to activity monitor and close the app
activity_monitor = app_with_bundle_identifier 'com.apple.ActivityMonitor'
terminate activity_monitor

# Close the Finder window
select_menu_item finder, 'File', 'Close Window'
