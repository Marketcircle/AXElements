class Symbol

  # Tells you if the symbol would be a predicate method by
  # checking if it ends with a question mark '?'.
  def predicate?
    to_s.match( /\?$/ ).is_a? MatchData
  end

end
