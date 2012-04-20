class TestMouseModule < MiniTest::Unit::TestCase

  def distance point1, point2
    x = point1.x - point2.x
    y = point1.y - point2.y
    Math.sqrt((x**2) + (y**2))
  end

  def test_move_to
    point = CGPoint.new(100, 100)
    Mouse.move_to point
    assert_in_delta 0, distance(point,Mouse.current_position), 1.0

    point = CGPoint.new(rand(700)+150, rand(500)+100)
    Mouse.move_to point
    assert_in_delta 0, distance(point,Mouse.current_position), 1.0
  end

end
