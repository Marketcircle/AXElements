#
#  rb_main.rb
#  AXElementsTester
#
#  Created by Mark Rada on 11-06-26.
#  Copyright (c) 2011 Marketcircle Incorporated. All rights reserved.
#

# Loading the Cocoa framework. If you need to load more frameworks, you can
# do that here too.
framework 'Cocoa'
framework 'Webkit'

# Laaaaaame
framework '/System/Library/Frameworks/CoreGraphics.framework'

# Loading all the Ruby project files.
main = File.basename(__FILE__, File.extname(__FILE__))
dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
Dir.glob(File.join(dir_path, '*.{rb,rbo}')).map { |x| File.basename(x, File.extname(x)) }.uniq.each do |path|
  if path != main
    require(path)
  end
end

# Starting the Cocoa main loop.
NSApplicationMain(0, nil)
