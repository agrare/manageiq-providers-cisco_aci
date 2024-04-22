class ManageIQ::Providers::CiscoAci::Inventory::Collector < ManageIQ::Providers::Inventory::Collector
  def top_system
    response = connection.get("/api/class/topSystem.json")
    imdata = JSON.parse(response.body)["imdata"]
    imdata.map { |data| data["topSystem"] }
  end

  private

  def connection
    @connection ||= manager.connect
  end
end
