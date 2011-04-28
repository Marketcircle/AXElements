# @todo this is totally broken right now
# class TestAXWaitForNotification < TestCore
#   def test_wait_for_finder_prefs
#     got_notification = false
#     AX::FINDER.show_about_window
#     AX.wait_for_notification(FINDER, KAXWindowCreatedNotification, 1.0) {
#       |element, notif|
#       got_notification = true if element.is_a?('AX::StandardWindow')
#     }
#     assert got_notification
#   end
#   def test_waits_the_given_timeout
#   end
# end
