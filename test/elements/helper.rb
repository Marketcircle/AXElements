class TestElements < TestAX

  EL_DOCK_APP =
    AX.attr_of_element(LIST, KAXChildrenAttribute).find { |x|
    x.class == AX::ApplicationDockItem
  }

end
