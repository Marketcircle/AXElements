require 'rubygems'
task :default => :test

def safe_require path, name
  require path
  yield
rescue LoadError => e
  $stderr.puts "It seems as though you do not have #{name} installed."
  command = ENV['RUBY_VERSION'] ? 'gem' : 'sudo macgem'
  $stderr.puts "You can install it by running `#{command} install #{name}`."
end


## Documentation

safe_require 'yard', 'yard' do
  YARD::Rake::YardocTask.new
end

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

end

require 'rake/compiletask'
Rake::CompileTask.new(:rbo)

## Testing

desc 'Build the test fixture'
task :fixture do
  sh 'cd test/AXElementsTester && xcodebuild && open ../fixture/Release/AXElementsTester.app'
end

desc 'Run benchmarks'
task :benchmark do
  files = Dir.glob('bench/**/bench_*.rb').map { |x| "'#{x}'" }.join(' ')
  ruby '-Ilib -Ibench -rhelper ' + files
end
task :bench => :benchmark

require 'rake/testtask'
Rake::TestTask.new(:test) do |t|
  t.libs     << 'test'
  t.pattern   = 'test/**/test_*.rb'
  t.ruby_opts = ['-rhelper']
  t.verbose   = true
end

## Gem Packaging
require 'rubygems/dependency_installer'
require 'rake/gempackagetask'

spec = Gem::Specification.load('AXElements.gemspec')

Rake::GemPackageTask.new(spec) { }

# This only installs this gem, it does not take deps into consideration
desc 'Build gem and install it'
task :install => :gem do
  Gem::Installer.new("pkg/#{spec.file_name}").install
end

desc 'Install development dependencies'
task :install_deps do
  (spec.runtime_dependencies + spec.development_dependencies).each do |dep|
    Gem::DependencyInstaller.new.install(dep.name, dep.requirement)
  end
end
