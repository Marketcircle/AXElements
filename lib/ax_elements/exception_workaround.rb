##
# Workaround for MacRuby ticket #1334
class Exception
  alias_method :original_message, :message
  #
  # Override the message method to force the backtrace to be
  # included.
  #
  # @return [String]
  def message
    "#{original_message}\n\t#{backtrace.join("\n\t")}"
  end
end
