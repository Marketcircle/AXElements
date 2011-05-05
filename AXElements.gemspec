$LOAD_PATH.unshift File.join( File.dirname(__FILE__), 'lib' )
require 'AXElements/Version'

GEM_SPEC = Gem::Specification.new do |s|
  s.name    = 'AXElements'
  s.version = AX::VERSION

  s.summary     = 'A DSL for automating GUI manipulation'
  s.description = <<-EOS
AXElements is a DSL abstraction on top of the Mac OS X Accessibility Framework
that allows code to be written in a very natural and declarative style that
describes user interactions.
  EOS
  s.authors     = ['Mark Rada']
  s.email       = 'mrada@marketcircle.com'
  s.homepage    = 'http://samurai.marketcircle.com:3000/docs/AXElements'
  s.licenses    = ['MIT']
  s.has_rdoc    = 'yard'

  s.files            =
    Dir.glob('lib/**/*.rb*')  +
    Dir.glob('vendor/**/*')
  s.test_files       =
    [ 'Rakefile', 'test/helper.rb' ] +
    Dir.glob('test/**/test_*.rb')
  s.extra_rdoc_files =
    [ 'LICENSE.txt', 'README.markdown', '.yardopts' ] +
    Dir.glob('docs/**/*')

  s.add_development_dependency 'minitest-macruby-pride', ['~> 2.2.0']
  s.add_development_dependency 'yard',                   ['~> 0.6.8']
  s.add_development_dependency 'redcarpet',              ['~> 1.12.2']
end
