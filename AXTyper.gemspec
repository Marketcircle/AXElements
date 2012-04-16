require './lib/accessibility/version'

Gem::Specification.new do |s|
  s.name     = 'AXTyper'
  s.version  = Accessibility::VERSION

  s.summary     = 'Keyboard simulation via accessibility'
  s.description = <<-EOS
Simulate keyboard input via the Mac OS X Accessibility Framework. This
gem is a component of AXElements.
  EOS
  s.authors     = ['Mark Rada']
  s.email       = 'mrada@marketcircle.com'
  s.homepage    = 'http://github.com/Marketcircle/AXElements'
  s.licenses    = ['BSD 3-clause']
  s.has_rdoc    = 'yard'
  s.extensions << 'ext/accessibility/key_coder/extconf.rb'


  s.files            = [
    'lib/accessibility/version.rb',
    'lib/accessibility/string.rb',
    'ext/accessibility/key_coder/key_coder.c',
    'ext/accessibility/key_coder/extconf.rb'
  ]
  s.test_files       = [
    'test/sanity/accessibility/test_string.rb',
    'test/runner.rb'
  ]
  s.extra_rdoc_files = [
    'README.typer.markdown',
    '.yardopts_typer',
  ]


  s.add_development_dependency 'minitest',  '~> 2.12'
  s.add_development_dependency 'yard',      '~> 0.7.5'
  s.add_development_dependency 'redcarpet', '~> 1.17'
end
