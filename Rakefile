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
task :console => :key_coder do
  irb = ENV['RUBY_VERSION'] ? 'irb' : 'macirb'
  sh "#{irb} -Ilib -Iext -rubygems -rax_elements"
end

## Compilation

require 'rake/compiletask'
Rake::CompileTask.new :rbo

desc 'Compile the C extension'
task :key_coder do
  Dir.chdir 'ext/key_coder' do
    break if File.exists?('key_coder.bundle') && File.mtime('key_coder.bundle') > File.mtime('key_coder.m')
    ruby 'extconf.rb'
    sh   'make'
  end
end

desc 'Clean temporary files created by the C extension'
task :clobber_key_coder do
  Dir.chdir 'ext/key_coder' do
    ['Makefile', 'key_coder.o', 'key_coder.bundle'].each do |file|
      $stdout.puts "rm ext/key_coder/#{file}"
      rm file
    end
  end
end
task :clobber => :clobber_key_coder

## Testing

desc 'Build the test fixture'
task :fixture do
  sh 'cd test/AXElementsTester && xcodebuild && open ../fixture/Release/AXElementsTester.app'
end

desc 'Run benchmarks'
task :benchmark => :key_coder do
  files = Dir.glob('bench/**/bench_*.rb').map { |x| "'#{x}'" }.join(' ')
  ruby '-Ilib -Iext -Ibench -rhelper ' + files
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
