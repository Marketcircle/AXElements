require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "AXElements"
  gem.homepage = "http://www.marketcircle.com/AXElements"
  gem.license = "MIT"
  gem.summary = %Q{A simple layer above the Mac OS X Accessibility APIs}
  gem.description = %Q{Takes advantage of the new Bridge Support in Mac OS X Lion to}
  gem.email = "mrada@marketcircle.com"
  gem.authors = ["Mark Rada"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  #  gem.add_runtime_dependency 'jabber4r', '> 0.1'
  gem.add_development_dependency 'minitest', '> 2.0.0'
  gem.add_development_dependency 'yard', '> 0.6.3'
  gem.requirements << 'BridgeSupport 2.0'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:unit) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :test => [:spec, :unit]

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new

task :garden do
  sh 'yard graph --dependencies --dot="-o docs/images/AX.png -Tpng:quartz"'
end

task :show_off do
  sh 'yard server --reload'
end

begin
  require 'reek/rake/task'
  Reek::Rake::Task.new do |t|
    t.fail_on_error = true
    t.verbose = false
    t.source_files = 'lib/**/*.rb', 'AXElements/lib/**/*.rb', 'AXHarness/lib/**/*.rb', 'AXContinuousIntegration/lib/**/*.rb'
  end
rescue LoadError
  task :reek do
    abort 'Reek is not available. In order to run reek, you must: sudo gem install reek'
  end
end
