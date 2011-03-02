module AX

  # Duh.
  VERSION = '0.1.2'

  # A list of dependencies
  RUNTIME_DEPENDENCIES = {
    i18n:          '0.5.0',
    activesupport: '3.0.5'
  }

  # Point of entry for any runtime dependencies
  GEM_PATH = File.absolute_path "#{File.dirname __FILE__}/../../gems"

  # Specify load paths to get around needing rubygems
  RUNTIME_DEPENDENCIES.each_pair { |dep, version|
    $LOAD_PATH.unshift "#{GEM_PATH}/#{dep}-#{version}/lib"
  }

end
