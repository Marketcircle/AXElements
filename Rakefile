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

desc 'Start up IRb with AXElements loaded'
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

eval IO.read('AXElements.gemspec')

Rake::GemPackageTask.new(GEM_SPEC) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = true
end

# This only works as long as I have no dependencies?
desc 'Build the gem and install it'
task :install => :gem do
  Gem::Installer.new("pkg/#{GEM_SPEC.file_name}").install
end
