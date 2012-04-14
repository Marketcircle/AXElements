require 'accessibility/debug'

module Accessibility

  ##
  # Error raised when an implicit search fails to return a result.
  class SearchFailure < NoMethodError

    def initialize searcher, searchee, filters
      filters = {} unless filters.kind_of? Hash
      msg  = "Could not find `#{pp_searchee searchee, filters}` "
      msg << "as a child of #{searcher.class}\n"
      msg << "Element Path:\n\t" << path_to(searcher)
      # @todo Consider turning this on by default
      msg << "\nSubtree:\n\t" << debug(searcher) if Accessibility::Debug.on?
      super msg
    end


    private

    def pp_searchee searchee, filters
      Accessibility::Qualifier.new(searchee, filters).describe
    end

    def path_to element
      Accessibility::Debug.path(element).map! { |x| x.inspect }.join("\n\t")
    end

    def debug searcher
      Accessibility::Debug.text_subtree(searcher)
    end
  end

  ##
  # Error raised when a timeout occurs in a polling method, such as
  # {DSL#wait_for}.
  class PollingTimeout < SearchFailure

    ##
    # Override the message to be more appropriate.
    def message
      msg = super
      msg.sub! /^Could not find/, 'Timed out waiting for'
      msg
    end

  end

end
