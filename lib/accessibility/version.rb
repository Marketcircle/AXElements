# -*- coding: utf-8 -*-

##
# The main AXElements namespace.
module Accessibility
  # @return [String]
  VERSION   = '1.0.0.beta4'

  # @return [String]
  CODE_NAME = case RUBY_ENGINE
              when 'macruby' then 'サンダース'
              when 'ruby'    then 'ブースター'
              when 'rbx'     then 'ブラッキー' # for when rbx has good cext support
              else 'シャワーズ' # vapor(ware)eon
              end

  ##
  # The complete version string for AXElements
  #
  # This differs from {Accessibility::VERSION} in that it also
  # includes `RUBY_ENGINE` information.
  #
  # @return [String]
  def self.version
    "#{VERSION}-#{CODE_NAME}"
  end

end
