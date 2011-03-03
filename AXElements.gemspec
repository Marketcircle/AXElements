$LOAD_PATH.unshift File.expand_path 'lib'
require 'AXElements/Version'

Gem::Specification.new do |s|
  s.name    = 'AXElements'
  s.version = AX::VERSION

  s.required_rubygems_version = Gem::Requirement.new '>= 1.4.2'
  s.rubygems_version          = Gem::VERSION
  s.requirements              = ['BridgeSupport Preview 3']

  s.summary       = 'An abstraction on top of the Mac OS X Accessibility APIs'
  s.description   = <<-EOS
Takes advantage of the new Bridge Support in Mac OS X Lion to build an object
oriented framework from the low level CoreFoundation API for accessibility.
  EOS
  s.authors       = ['Mark Rada']
  s.email         = 'mrada@marketcircle.com'
  s.homepage      = 'http://samurai.marketcircle.com:3000/docs/AXElements'
  s.licenses      = ['MIT']
  s.has_rdoc      = 'yard'
  s.require_paths = ['lib']

  s.files            =
    Dir.glob('lib/**/*.rb*')  +
    Dir.glob('gems/**/*.rbo')
  s.test_files       =
    Dir.glob('spec/**/*_spec.rb') +
    [ 'spec/helper.rb' ]
  s.extra_rdoc_files =
    [ 'Rakefile', 'LICENSE.txt', 'README.markdown', '.yardopts' ] +
    Dir.glob('docs/**/*')

  s.add_development_dependency 'rake',      ['>= 0.8.7']
  s.add_development_dependency 'rspec',     ['~> 2.5']
  s.add_development_dependency 'yard',      ['~> 0.6.4']
  s.add_development_dependency 'bluecloth', ['~> 2.0.11']
end
