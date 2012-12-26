require './lib/accessibility/version'

Gem::Specification.new do |s|
  s.name     = 'AXElements'
  s.version  = Accessibility::VERSION

  s.summary     = 'A DSL for automating GUI manipulation'
  s.description = <<-EOS
AXElements is a UI automation DSL built on top of the Mac OS X Accessibility
Framework that allows code to be written in a very natural and declarative
style that describes user interactions.
  EOS
  s.authors     = ['Mark Rada']
  s.email       = 'mrada@marketcircle.com'
  s.homepage    = 'http://github.com/Marketcircle/AXElements'
  s.licenses    = ['BSD 3-clause']
  s.has_rdoc    = 'yard'
  s.extensions << 'ext/accessibility/key_coder/extconf.rb'


  s.files            =
    Dir.glob('lib/**/*.rb*') +
    Dir.glob('ext/**/*{.rb,.m,.c}') +
    Dir.glob('rakelib/*.rake') +
    ['Rakefile', 'README.markdown', 'History.markdown', '.yardopts']
  s.test_files       =
    Dir.glob('test/**/test_*.rb') +
    [ 'test/helper.rb' ]


  s.add_runtime_dependency 'mouse',              '~> 1.0.5'
  s.add_runtime_dependency 'screen_recorder',    '~> 0.1.5'
  s.add_runtime_dependency 'accessibility_core', '~> 0.3.2'
  s.add_runtime_dependency 'activesupport',      '~> 3.2.9'


  s.add_development_dependency 'yard',     '~> 0.8.3'
  s.add_development_dependency 'kramdown', '~> 0.14.1'
end
