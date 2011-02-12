require 'rubygems'
require 'bundler'

begin
  Bundler.setup :default, :development
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end
require 'rake'

task :test    => :spec
task :default => :test


namespace :macruby do
  desc 'AOT compile for MacRuby'
  task :compile do
    FileList["lib/**/*.rb"].each do |source|
      name = File.basename source
      puts "#{name} => #{name}o"
      # @todo link against ApplicationServices
      `macrubyc --arch x86_64 -C '#{source}' -o '#{source}o'`
    end
  end

  desc 'AOT compile dependencies for MacRuby'
  task :compile_deps do
    FileList["gems/**/*.rb"].each do |source|
      name = File.basename source
      puts "#{name} => #{name}o"
      # @todo link against ApplicationServices
      `macrubyc --arch x86_64 -C '#{source}' -o '#{source}o'`
      rm source
    end
  end

  desc 'Clean MacRuby binaries'
  task :clean do
    FileList["lib/**/*.rbo"].each do |bin|
      puts "rm #{bin}"
      rm bin
    end
  end
end


namespace :gem do
  desc 'Build the gem'
  task :build => [:'macruby:compile', :'macruby:compile_deps'] do
    puts `gem build -v AXElements.gemspec`
  end

  desc 'Build the gem and install it'
  task :install => :build do
    puts `gem install -v #{Dir.glob('./AXElements*.gem').sort.reverse.first}`
  end
end


###
# Tests

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

# RSpec::Core::RakeTask.new(:rcov) do |spec|
#   spec.pattern = 'spec/**/*_spec.rb'
#   spec.rcov = true
# end


###
# Documentation

require 'yard'
YARD::Rake::YardocTask.new

namespace :yard do
  desc 'Generate Graphviz object graph'
  task :garden do
    `yard graph --full --dependencies --dot="-Tpng:quartz" -f docs/images/AX.png`
  end
end
