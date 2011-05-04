class TestElements < TestAX

  EL_DOCK = AX.application_for_pid(DOCK_PID)

  EL_DOCK_APP =
    AX.attr_of_element(LIST, KAXChildrenAttribute).find { |x|
    x.class == AX::ApplicationDockItem
  }

  EL_SYSTEM = AX::SystemWide.instance

end
