# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path 'lib'
require 'AXElements/Version'

Gem::Specification.new do |s|
  s.name    = 'AXElements'
  s.version = AX::VERSION

  s.required_rubygems_version = '>= 1.4.2'
  s.rubygems_version          = '1.4.2'
  s.requirements              = ['BridgeSupport 2.0']

  s.summary       = 'An abstraction on top of the Mac OS X Accessibility APIs'
  s.description   = <<-EOS
Takes advantage of the new Bridge Support in Mac OS X Lion to build an object
oriented framework from the low level CoreFoundation API for accessibility.
  EOS
  s.authors       = ['Mark Rada']
  s.email         = 'mrada@marketcircle.com'
  s.homepage      = 'http://samurai.marketcircle.com:3000/docs/AXElements'
  s.licenses      = ['MIT']
  s.has_rdoc      = true
  s.require_paths = ['lib']

  s.files            =
    Dir.glob('lib/**/*.rb*')  +
    Dir.glob('gems/**/*.rbo')
  s.test_files       =
    Dir.glob 'spec/**/*_spec.rb'
  s.extra_rdoc_files =
    [ 'LICENSE.txt', 'README.markdown', '.yardopts' ] +
    Dir.glob('docs/**/*')

  # They are development dependencies because the runtime versions
  # are already installed and packaged gems directory.
  s.add_development_dependency 'i18n',          ['~> 0.5.0']
  s.add_development_dependency 'activesupport', ['~> 3.0.4']

  s.add_development_dependency 'rake',      ['~> 0.8.7']
  s.add_development_dependency 'rspec',     ['~> 2.5.0']
  s.add_development_dependency 'yard',      ['~> 0.6.4']
  s.add_development_dependency 'bluecloth', ['~> 2.0.11']
#  s.add_development_dependency 'rcov',      ['>= 0']
end
