# -*- coding: utf-8 -*-
class TestAccessibilityCoreErrorHandler < MiniTest::Unit::TestCase
  include Accessibility::Core

  def ref
    @@description ||= Regexp.new(Regexp.escape(REF.description))
  end

  def error_handler_test args, should_raise: klass, with_fragments: msgs
    @@meth ||= Regexp.new "`#{__method__}'$"
    handle_error *args
  rescue Exception => e
    assert_instance_of klass, e, e.inspect
    assert_match @@meth, e.backtrace.first, e.backtrace
    msgs.each do |msg|
      assert_match msg, e.message
    end
  end

  def test_has_failsafe_exception
    error_handler_test [99],
         should_raise: RuntimeError,
       with_fragments: [/never reach this line/, /99/]
  end

  def test_failure
    error_handler_test [KAXErrorFailure, REF],
         should_raise: RuntimeError,
       with_fragments: [/system failure/, ref]
  end

  def test_illegal_argument
    skip 'OMG, PLEASE NO'
  end

  def test_invalid_element
    error_handler_test [KAXErrorInvalidUIElement, REF],
         should_raise: ArgumentError,
       with_fragments: [/no longer a valid reference/, ref]
  end

  def test_invalid_observer
    error_handler_test [KAXErrorInvalidUIElementObserver, REF, :pie, :cake],
         should_raise: ArgumentError,
       with_fragments: [/no longer a valid observer/, /or was never valid/, ref, /cake/]
  end

  def test_cannot_complete
    def pid_for lol
      NSRunningApplication
        .runningApplicationsWithBundleIdentifier('com.apple.finder')
        .first.processIdentifier
    end
    error_handler_test [KAXErrorCannotComplete, REF],
         should_raise: RuntimeError,
       with_fragments: [/Some unspecified error/, ref, /:\(/]

    def pid_for lol; false; end
    error_handler_test [KAXErrorCannotComplete, nil],
         should_raise: RuntimeError,
       with_fragments: [/Application for pid/, /Maybe it crashed\?/]
  end

  def test_attr_unsupported
    error_handler_test [KAXErrorAttributeUnsupported, REF, :cake],
         should_raise: ArgumentError,
       with_fragments: [/does not have/, /:cake attribute/, ref]
  end

  def test_action_unsupported
    error_handler_test [KAXErrorActionUnsupported, REF, :pie],
         should_raise: ArgumentError,
       with_fragments: [/does not have/, /:pie action/, ref]
  end

  def test_notif_unsupported
    error_handler_test [KAXErrorNotificationUnsupported, REF, :cheese],
         should_raise: ArgumentError,
       with_fragments: [/does not support/, /:cheese notification/, ref]
  end

  def test_not_implemented
    error_handler_test [KAXErrorNotImplemented, REF],
         should_raise: NotImplementedError,
       with_fragments: [/does not work with AXAPI/, ref]
  end

  def test_notif_registered
    error_handler_test [KAXErrorNotificationAlreadyRegistered, REF, :lamp],
         should_raise: ArgumentError,
       with_fragments: [/already registered/, /:lamp/, ref]
  end

  def test_notif_not_registered
    error_handler_test [KAXErrorNotificationNotRegistered, REF, :peas],
         should_raise: RuntimeError,
       with_fragments: [/not registered/, /:peas/, ref]
  end

  def test_api_disabled
    error_handler_test [KAXErrorAPIDisabled],
         should_raise: RuntimeError,
       with_fragments: [/AXAPI has been disabled/]
  end

  def test_param_attr_unsupported
    error_handler_test [KAXErrorParameterizedAttributeUnsupported, REF, :oscar],
         should_raise: ArgumentError,
       with_fragments: [/does not have/, /:oscar parameterized attribute/, ref]
  end

  def test_not_enough_precision
    error_handler_test [KAXErrorNotEnoughPrecision],
         should_raise: RuntimeError,
       with_fragments: [/not enough precision/, "¯\(°_o)/¯"]
  end

end
