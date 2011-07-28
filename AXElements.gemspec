$LOAD_PATH.unshift File.join( File.dirname(__FILE__), 'lib' )
require 'ax_elements/version'

Gem::Specification.new do |s|
  s.name     = 'AXElements'
  s.version  = Accessibility::VERSION
  s.platform = Gem::Platform::MACRUBY

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

  s.require_paths << 'ext'
  s.extensions    << 'ext/key_coder/extconf.rb'


  s.files            =
    Dir.glob('lib/**/*.rb*') +
    [ 'ext/key_coder/extconf.rb', 'ext/key_coder/key_coder.m' ] +
  s.test_files       =
    [ 'Rakefile', 'test/helper.rb' ] +
    Dir.glob('test/**/test_*.rb')
  s.extra_rdoc_files =
    [ 'LICENSE.txt', 'README.markdown', '.yardopts' ] +
    Dir.glob('docs/**/*')

  s.add_runtime_dependency 'activesupport', ['~> 3.0.9']
  s.add_runtime_dependency 'i18n',          ['~> 0.6.0']

  s.add_development_dependency 'minitest-macruby-pride', ['~> 2.3.1']
  s.add_development_dependency 'yard',                   ['~> 0.7.2']
  s.add_development_dependency 'redcarpet',              ['~> 1.17']
end
