# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name    = 'AXElements'
  s.version = '0.1.2'

  s.required_rubygems_version = '>= 1.4.2'
  s.rubygems_version          = '1.4.2'
  s.requirements              = ['BridgeSupport 2.0']

  s.summary     = 'A simple layer above the Mac OS X Accessibility APIs'
  s.description = 'Takes advantage of the new Bridge Support in Mac OS X Lion'
  s.authors     = ['Mark Rada']
  s.email       = 'mrada@marketcircle.com'
  s.homepage    = 'http://samurai.marketcircle.com:3000/docs/AXElements'
  s.licenses    = ['MIT']

  s.require_paths    = ['lib']
  s.files            = Dir.glob('/lib/**/*')
  s.test_files       = Dir.glob 'spec/**/*_spec.rb'
  s.extra_rdoc_files = [
                        'LICENSE.txt',
                        'README.markdown'
                       ]

  s.add_runtime_dependency 'AXElements',    ['>= 0']
  s.add_runtime_dependency 'i18n',          ['~> 0.5.0']
  s.add_runtime_dependency 'activesupport', ['~> 3.0.4']

  s.add_development_dependency 'rake',      ['~> 0.8.7']
  s.add_development_dependency 'rspec',     ['~> 2.5.0']
  s.add_development_dependency 'yard',      ['~> 0.6.4']
  s.add_development_dependency 'bluecloth', ['~> 2.0.10']
  s.add_development_dependency 'reek',      ['~> 1.2.8']
  s.add_development_dependency 'rcov',      ['~> 0.9.9']
end
