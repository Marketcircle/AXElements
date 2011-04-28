require 'core/helper'


class TestPIDOfElement < TestCore

  def test_pid_of_app
    assert_equal FINDER_PID, AX.pid_of_element(FINDER)
  end

  def test_pid_of_dock_app_is_docks_pid
    assert_equal DOCK_PID, AX.pid_of_element(finder_dock_item)
  end

end


# I'd prefer to not have to directly call the log method bypassing
# the fact that it is a private method.
class TestLogAXCall < TestCore

  def test_code_is_returned
    assert_equal KAXErrorIllegalArgument, AX.send(:log_ax_call, DOCK, KAXErrorIllegalArgument)
    assert_equal KAXErrorAPIDisabled, AX.send(:log_ax_call, DOCK, KAXErrorAPIDisabled)
    assert_equal KAXErrorSuccess, AX.send(:log_ax_call, DOCK, KAXErrorSuccess)
  end

  def test_logs_nothing_for_success_case
    with_logging { AX.send(:log_ax_call, DOCK, KAXErrorSuccess) }
    assert_empty @log_output.string
  end

  def test_looks_up_code_properly
    with_logging { AX.send(:log_ax_call, DOCK, KAXErrorAPIDisabled) }
    assert_match /API Disabled/, @log_output.string
    with_logging { AX.send(:log_ax_call, DOCK, KAXErrorNotImplemented) }
    assert_match /Not Implemented/, @log_output.string
  end

end


class TestStripPrefix < MiniTest::Unit::TestCase

  def test_removes_ax_prefix; prefix_test 'AXButton', 'Button'; end

  def test_removes_combination_prefixes; prefix_test 'MCAXButton', 'Button'; end

  def test_works_with_all_caps; prefix_test 'AXURL', 'URL'; end

  def test_works_with_long_name; prefix_test 'AXIsApplicationRunning', 'ApplicationRunning'; end

  def test_is_not_greedy; prefix_test 'AXAX', 'AX'; end

  def prefix_test before, after
    assert_equal after, AX.strip_prefix(before)
  end

end
