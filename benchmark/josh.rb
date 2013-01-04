require 'benchmark'
require 'rubygems'
require 'ax_elements'

n      = 1_000
safari = AX::Application.new 'com.apple.Safari'

Benchmark.bmbm do |bm|
  bm.report("attribute lookup") {
    n.times { safari.main_window }
  }
  bm.report("attribute lookup 2") {
    n.times { safari.attribute(:main_window) }
  }
  bm.report("parameterized attribute lookup") {
    field = safari.main_window.toolbar.text_field(id: /ADDRESS_AND_SEARCH/)
    n.times { field.string_for_range 0..3 }
  }
  bm.report("parameterized attribute lookup2") {
    field = safari.main_window.text_field
    n.times { field.parameterized_attribute :string_for_range, 0..3 }
  }
  bm.report("simply query") {
    n.times { safari.search(:close_button) }
  }
  bm.report("query with block") {
    n.times { 
      safari.search(:static_text) do |element|
        true
      end
    }
  }
  bm.report("complex query") { 
    safari.search(:buttons, ancestor: { button: { title: /MacRuby/i } })
  }
  bm.report("failing queury") {
    safari.search(:herp, derp: 42)
  }
  bm.report("inspect_subtree") { 
    safari.inspect_subtree 
  }
end

