require 'mkmf'

$CFLAGS << ' -std=c99 -fobjc-gc -Wall -Werror'
$LIBS   << ' -framework Cocoa -framework CoreServices -framework Carbon'

unless RUBY_ENGINE == 'macruby'
  $CFLAGS << ' -DNOT_MACRUBY -fblocks'
end

create_makefile('accessibility/key_coder')
