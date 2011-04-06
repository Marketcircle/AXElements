$LOAD_PATH.unshift File.expand_path 'lib'
require 'AXElements/Version'

Gem::Specification.new do |s|
  s.name    = 'AXElements'
  s.version = AX::VERSION

  s.required_rubygems_version = Gem::Requirement.new '>= 1.4.2'
  s.rubygems_version          = Gem::VERSION
  s.requirements              = ['BridgeSupport Preview 3']

  s.summary       = 'A DSL for automating GUI manipulation'
  s.description   = <<-EOS
AXElements is a DSL abstraction on top of the Mac OS X Accessibility Framework
that allows code to be written in a very natural and declarative style that
describes user interactions.
  EOS
  s.authors       = ['Mark Rada']
  s.email         = 'mrada@marketcircle.com'
  s.homepage      = 'http://samurai.marketcircle.com:3000/docs/AXElements'
  s.licenses      = ['MIT']
  s.has_rdoc      = 'yard'
  s.require_paths = ['lib']

  s.files            =
    Dir.glob('lib/**/*.rb*')  +
    Dir.glob('vendor/**/*')
  s.test_files       =
    Dir.glob('test/**/test_*.rb') +
    [ 'test/helper.rb' ]
  s.extra_rdoc_files =
    [ 'Rakefile', 'LICENSE.txt', 'README.markdown', '.yardopts' ] +
    Dir.glob('docs/**/*')

  s.add_development_dependency 'minitest-macruby-pride',  ['~> 2.1.2']
  s.add_development_dependency 'yard',                    ['~> 0.6.6']
  s.add_development_dependency 'bluecloth',               ['~> 2.0.11']
end
