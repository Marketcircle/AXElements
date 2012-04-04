require 'mkmf'

$CFLAGS << ' -std=c99 -Wall -Werror -ObjC'
$LIBS   << ' -framework Cocoa -framework Carbon -framework ApplicationServices'

if RUBY_ENGINE == 'macruby'
  $CFLAGS << ' -fobjc-gc'
else
  if clang = `which clang`.chomp
    unless RbConfig::CONFIG["CC"].match /clang/
      RbConfig::MAKEFILE_CONFIG["CC"]  = clang
      RbConfig::MAKEFILE_CONFIG["CXX"] = clang
    end
  else
    $stdout.puts "Clang not installed. Cannot build C extension"
  end
  $CFLAGS << ' -DNOT_MACRUBY'
end

create_makefile('accessibility/key_coder')
