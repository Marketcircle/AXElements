require 'rubygems/package_task'

ax_elements = Gem::Specification.load('AXElements.gemspec')
Gem::PackageTask.new(ax_elements) { }

desc 'Build and install gem (not including deps)'
task :install => :gem do
  require 'rubygems/installer'
  Gem::Installer.new("pkg/#{ax_elements.file_name}").install
end

desc 'Install dependencies for development'
task :setup_dev do
  require 'rubygems/dependency_installer'
  ax_elements.development_dependencies.each do |dep|
    puts "Installing #{dep.name} (#{dep.requirement})"
    Gem::DependencyInstaller.new.install(dep.name, dep.requirement)
  end
end

ax_typer = Gem::Specification.load('AXTyper.gemspec')
Gem::PackageTask.new(ax_typer) { }

desc 'Build and install AXTyper'
task :install_typer => :gem do
  require 'rubygems/installer'
  Gem::Installer.new("pkg/#{ax_typer.file_name}").install
end
