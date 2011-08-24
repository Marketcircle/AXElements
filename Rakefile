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
task :console => :ext do
  irb = ENV['RUBY_VERSION'] ? 'irb' : 'macirb'
  sh "#{irb} -Ilib -Iext/key_coder -rubygems -rax_elements"
end

## Compilation

require 'rake/compiletask'
Rake::CompileTask.new

desc 'Compile C extensions'
task :ext do
  Dir.chdir 'ext/key_coder' do
    break if File.exists?('key_coder.bundle') && File.mtime('key_coder.bundle') > File.mtime('key_coder.m')
    ruby 'extconf.rb'
    sh   'make'
  end
end

desc 'Clean temporary files created by the C extension'
task :clobber_ext do
  Dir.chdir 'ext/key_coder' do
    ['Makefile', 'key_coder.o', 'key_coder.bundle'].each do |file|
      $stdout.puts "rm ext/key_coder/#{file}"
      rm file
    end
  end
end
task :clobber => :clobber_ext

## Testing

desc 'Build the test fixture'
task :fixture do
  sh 'cd test/AXElementsTester && xcodebuild'
end

desc 'Run benchmarks'
task :benchmark => :ext do
  files = Dir.glob('bench/**/bench_*.rb').map { |x| "'#{x}'" }.join(' ')
  ruby '-Ilib -Iext -Ibench -rhelper ' + files
end
task :bench => :benchmark

require 'rake/testtask'
Rake::TestTask.new(:test) do |t|
  t.libs     << 'test' << 'ext/key_coder'
  t.pattern   = 'test/**/test_*.rb'
  t.ruby_opts = ['-rhelper']
  t.verbose   = true
end
task :test => [:ext, :fixture]

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

desc 'Install dependencies for development'
task :setup_dev do
  (spec.runtime_dependencies + spec.development_dependencies).each do |dep|
    Gem::DependencyInstaller.new.install(dep.name, dep.requirement)
  end
end

desc 'Install dependencies for a test node'
task :setup_node do
  (spec.runtime_dependencies).each do |dep|
    Gem::DependencyInstaller.new.install(dep.name, dep.requirement)
  end
end
