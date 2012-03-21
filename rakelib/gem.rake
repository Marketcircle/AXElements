require 'rubygems/package_task'
spec = Gem::Specification.load('AXElements.gemspec')
Gem::PackageTask.new(spec) { }

desc 'Build and install gem (not including deps)'
task :install => :gem do
  require 'rubygems/installer'
  Gem::Installer.new("pkg/#{spec.file_name}").install
end

desc 'Install dependencies for development'
task :setup_dev do
  require 'rubygems/dependency_installer'
  spec.development_dependencies.each do |dep|
    puts "Installing #{dep.name} (#{dep.requirement})"
    Gem::DependencyInstaller.new.install(dep.name, dep.requirement)
  end
end
