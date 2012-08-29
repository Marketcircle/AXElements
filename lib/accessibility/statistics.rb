require 'accessibility/version'

class Accessibility::Statistics

  def initialize
    @stats = Hash.new do |h,k| h[k] = 0 end
    @q     = Dispatch::Queue.new "com.marketcircle.axelements.stats"
  end

  def increment key
    @q.async do
      @stats[key] += 1
    end
  end

  def to_s
    @q.sync do # must be synchronized
      set_max_length
      @out = output_header << output_body << "\n"
    end
    @out
  end


  private

  def set_max_length
    @max_key_len = @stats.keys.map(&:length).max
    @max_val_len = @stats.values.max.to_s.length
  end

  def dot key, val
    length  = 4
    length += @max_key_len - key.length
    length += @max_val_len - val.to_s.length
    "." * length
  end

  def output_header
    <<-EOS
######################
# AX Call Statistics #
######################
    EOS
  end

  def output_body
    @stats.keys.sort.map do |key|
      val = @stats[key]
      key.to_s << dot(key,val) << val.to_s
    end.join("\n")
  end

end

# @return [Accessibility::Statistics]
STATS = Accessibility::Statistics.new
