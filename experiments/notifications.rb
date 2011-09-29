framework 'Cocoa'

# make sure the fixture app is running first

workspace   = NSWorkspace.sharedWorkspace
running_app = workspace.runningApplications.find { |app| app.localizedName == 'AXElementsTester' }

app = AXUIElementCreateApplication(running_app.processIdentifier)

def attribute_for element, attr
  ptr = Pointer.new :id
  AXUIElementCopyAttributeValue(element, attr, ptr)
  ptr[0]
end

def children_for element
  attribute_for element, KAXChildrenAttribute
end

window = children_for(app).find do |item|
  attribute_for(item, KAXRoleAttribute) == KAXWindowRole
end

button = children_for(window).find do |item|
  attribute_for(item, KAXRoleAttribute) == KAXButtonRole &&
    attribute_for(item, KAXTitleAttribute) == 'Yes'
end

def make_observer_for pid
  ptr  = Pointer.new '^{__AXObserver}'
  code = AXObserverCreate(pid, Proc.new, ptr)
  ptr[0]
end


button_observer = make_observer_for running_app.processIdentifier do |observer, element, notif, _|
  puts 'button callback'
end
CFShow(button_observer)

app_observer = make_observer_for running_app.processIdentifier do |observer, element, notif, _|
  puts 'app callback'
end
CFShow(app_observer)


CHEEZ = 'Cheezburger'

# technically, we could reuse the same observer
AXObserverAddNotification(app_observer, app, CHEEZ, nil)
# AXObserverAddNotification(button_observer, button, CHEEZ, nil)

puts 'starting'
# have to add the fucking source
run_loop = CFRunLoopGetCurrent()
source   = AXObserverGetRunLoopSource(app_observer)
CFRunLoopAddSource(run_loop, source, KCFRunLoopDefaultMode)
CFRunLoopRunInMode(KCFRunLoopDefaultMode, 10.0, false)

# unregister
# problem?

# try with app
# try with specific element
# do I get the notification once, or is registration forever
