class ManageIQ::Providers::CiscoAci::Inventory::Parser < ManageIQ::Providers::Inventory::Parser
  def parse
    top_system
  end

  def top_system
    collector.top_system.each do |top_system|
      top_system["attributes"]
    end
  end
end
