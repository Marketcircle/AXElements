module AX

  VERSION = '0.2.1'
  CODE_NAME = 'Tiger Blood'

  # A list of dependencies
  RUNTIME_DEPENDENCIES = {
    'i18n'          => '0.5.0',
    'activesupport' => '3.0.5'
  }

  # Specify load paths to get around needing rubygems
  $LOAD_PATH.unshift File.absolute_path("#{File.dirname __FILE__}/../../vendor")

end
