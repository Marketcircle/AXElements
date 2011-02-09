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
  gem.name = 'AXElements'
  gem.homepage = 'http://samurai.marketcircle.com:3000/docs/AXElements'
  gem.license = 'MIT'
  gem.summary = 'A simple layer above the Mac OS X Accessibility APIs'
  gem.description = 'Takes advantage of the new Bridge Support in Mac OS X Lion to'
  gem.email = 'mrada@marketcircle.com'
  gem.authors = ['Mark Rada']
  gem.requirements << 'BridgeSupport 2.0'
  gem.files = ['lib/**/*']
  gem.add_dependency 'activesupport', '~> 3.0.4'
  gem.add_development_dependency 'jeweler',   '~> 1.5.2'
  gem.add_development_dependency 'rspec',     '~> 2.5.0'
  gem.add_development_dependency 'yard',      '~> 0.6.4'
  gem.add_development_dependency 'bluecloth', '~> 2.0.10'
  gem.add_development_dependency 'metric_fu', '~> 2.0.1'
  gem.test_files = Dir.glob('spec/*_spec.rb')
end
Jeweler::RubygemsDotOrgTasks.new

task :test => :spec
task :default => :spec

# @todo consider tying into https://github.com/cowboyd/hudson.rb
require 'metric_fu'
MetricFu::Configuration.run do |config|
  config.metrics = [:saikuro, :stats, :flog, :flay, :reek]
  config.graphs  = [:flog, :flay, :stats]
end

require 'rspec/core'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

#require 'rspec/core/rake_task'
#RSpec::Core::RakeTask.new(:rcov) do |spec|
#  spec.pattern = 'spec/**/*_spec.rb'
#  spec.rcov = true
#end

require 'yard'
YARD::Rake::YardocTask.new
task :garden do
  sh 'yard graph --dependencies --dot="-o docs/images/AX.png -Tpng:quartz"'
end
task :show_off do
  sh 'yard server --reload'
end
