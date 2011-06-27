require 'rubygems'
require 'yard'
require 'rake/compiletask'
require 'rake/testtask'
require 'rake/gempackagetask'
require 'rubygems/dependency_installer'


task :default => :test

## Documentation

YARD::Rake::YardocTask.new

desc 'Generate Graphviz object graph'
task :garden => :yard do
  sh 'yard graph --full --dependencies --dot="-Tpng:quartz" -f docs/images/AX.dot'
end

## Console

desc 'Start up irb with AXElements loaded'
task :console do
  irb = ENV['RUBY_VERSION'] ? 'irb' : 'macirb'
  sh "#{irb} -Ilib -rubygems -rAXElements"
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

desc 'Build the test fixture'
task :fixture do
  sh 'cd test/AXElementsTester && xcodebuild -configuration Debug && open ../Debug/AXElementsTester.app'
end

desc 'Run benchmarks'
task :benchmark do
  files = Dir.glob('bench/**/bench_*.rb').map { |x| "'#{x}'"}.join(' ')
  ruby '-Ilib -Ibench -rhelper ' + files
end
task :bench => :benchmark

Rake::TestTask.new(:test) do |t|
  t.libs     << 'test'
  t.pattern   = 'test/**/test_*.rb'
  t.ruby_opts = ['-rhelper']
  t.verbose   = true
end

## Gem Packaging

spec = Gem::Specification.load('AXElements.gemspec')

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = true
end

# This only works as long as I have no dependencies?
desc 'Build the gem and install it'
task :install => :gem do
  Gem::Installer.new("pkg/#{spec.file_name}").install
end
