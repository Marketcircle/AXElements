require 'mkmf'

$CFLAGS << ' -std=c99 -fobjc-gc -Wall -Werror'
$LIBS   << ' -framework Cocoa -framework CoreServices -framework Carbon'

create_makefile('accessibility/key_code_generator')
