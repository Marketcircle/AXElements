# -*- coding: utf-8 -*-

require 'logger'

module Accessibility
  VERSION   = '0.4.2'
  CODE_NAME = 'PokéMaster'

  class << self
    # @return [Logger]
    attr_accessor :log
  end

  @log = Logger.new $stderr
  @log.level = Logger::ERROR
end
