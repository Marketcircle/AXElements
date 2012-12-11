framework 'Cocoa'

MOUNTAIN_LION_APPKIT_VERSION ||= 1187
if NSAppKitVersionNumber >= MOUNTAIN_LION_APPKIT_VERSION
    framework '/System/Library/Frameworks/CoreGraphics.framework'
end

