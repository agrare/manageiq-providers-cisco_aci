class ManageIQ::Providers::CiscoAci::Inventory::Collector < ManageIQ::Providers::Inventory::Collector
  def connection
    @connection ||= manager.connect
  end

  def vms
    connection.vms
  end
end
