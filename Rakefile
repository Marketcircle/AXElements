require 'rubygems'
require 'yard'
require 'rake/compiletask'
require 'rake/testtask'
require 'rake/gempackagetask'
require 'rubygems/dependency_installer'
require 'lib/AXElements/Version'

task :default => :test

## Documentation

YARD::Rake::YardocTask.new

desc 'Generate Graphviz object graph'
task :garden do
  sh 'yard graph --full --dependencies --dot="-Tpng:quartz" -f docs/images/AX.dot'
end

## Console

desc 'Start up IRb with AXElements loaded'
task :console do
  irb = ENV['RUBY_VERSION'] ? 'irb' : 'macirb'
  sh "#{irb} -Ilib -rAXElements"
end

## Compilation

Rake::CompileTask.new do |t|
  t.files = FileList["lib/**/*.rb"]
  t.verbose = true
end

desc 'Clean MacRuby binaries'
task :clean do
  FileList["lib/**/*.rbo"].each do |bin|
    puts rm bin
  end
end

## Testing

test_suites = [:core, :elements, :mouse, :actions]
test_suites.each do |suite|
  namespace :test do
    Rake::TestTask.new(suite) do |t|
      t.libs << 'test'
      t.pattern = "test/#{suite}/test_*.rb"
      t.ruby_opts = ['-rhelper', "-r#{suite}/helper"]
      t.verbose = true
    end
  end
end
desc 'Run all test suites'
task :test => test_suites.map { |suite| "test:#{suite}" }

## Gem Packaging

GEM_SPEC = Gem::Specification.new do |s|
  s.name    = 'AXElements'
  s.version = AX::VERSION

  s.required_rubygems_version = Gem::Requirement.new '>= 1.4.2'
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

  s.files            =
    Dir.glob('lib/**/*.rb*')  +
    Dir.glob('vendor/**/*')
  s.test_files       =
    Dir.glob('test/**/test_*.rb') +
    [ 'test/helper.rb' ]
  s.extra_rdoc_files =
    [ 'Rakefile', 'LICENSE.txt', 'README.markdown', '.yardopts' ] +
    Dir.glob('docs/**/*')

  s.add_development_dependency 'minitest-macruby-pride', ['~> 2.2.0']
  s.add_development_dependency 'yard',                   ['~> 0.6.8']
  s.add_development_dependency 'redcarpet',              ['~> 1.11.0']
end

Rake::GemPackageTask.new(GEM_SPEC) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = true
end

# This only works as long as I have no dependencies?
desc 'Build the gem and install it'
task :install => :gem do
  Gem::Installer.new("pkg/#{GEM_SPEC.file_name}").install
end
