require 'mkmf'

$CFLAGS << ' -std=c99 -Wall -Werror -ObjC'
$LIBS   << ' -framework Cocoa -framework Carbon -framework ApplicationServices'

if RUBY_ENGINE == 'macruby'
  $CFLAGS << ' -fobjc-gc'
else
  $CFLAGS << ' -DNOT_MACRUBY -fblocks'
end

create_makefile('accessibility/key_coder')
