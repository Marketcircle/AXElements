require 'test/integration/helper'

class TestAXMenu < MiniTest::Unit::TestCase

  def test_item
    pop_up = app.main_window.pop_up
    click pop_up

    assert_respond_to pop_up.menu, :item

    assert_equal 'Togusa', pop_up.menu.item(title: 'Togusa').title

    pop_up.menu.item(title: '38') { |x| @got_called = true }
    assert @got_called

  ensure
    click pop_up if pop_up
  end


  def test_item_raises
    pop_up = app.main_window.pop_up
    click pop_up
    assert_raises(Accessibility::SearchFailure) { pop_up.menu.item(herp: 'derp') }
  ensure
    click pop_up if pop_up
  end

end
